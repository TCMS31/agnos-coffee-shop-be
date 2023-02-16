# Bug reproductions

Each of these was reproduced against the code as it stood at commit `9d8516a`
(the last commit before this uplift), extracted with `git archive HEAD` into a
scratch directory and run against a throwaway database. This is the literal
output of that script.

```console
$ bundle exec ruby repro.rb
== BUG 1: routes declare resources :discounts but no controller exists ==
ActionController::RoutingError: A route matches "/api/v1/discounts", but references missing controller: Api::V1::DiscountsController

== BUG 2: OrderItem with a non-existent item_id ==
NoMethodError: undefined method `available_quantity' for nil:NilClass

== BUG 3: negative quantity increases stock ==
stock before 5, quantity ordered -3, stock after: 8

== BUG 4: discount factory writes a column that does not exist ==
NoMethodError: undefined method `discount_percentage=' for #<Discount:0x0000000a7e615ae8>
Did you mean?  discount_with_item_id_change

== BUG 5: BaseController#resource assigns @resources ==
def resource
        @resources ||= model.find(params[:id])
      end
```

## What each one was

1. **`/api/v1/discounts` was routed but had no controller.** `config/routes.rb`
   declared `resources :discounts` from the first commit; `Api::V1::DiscountsController`
   was never written. Managing paired discounts is one of the six features the
   README claims. Fixed by writing the controller and its serializer.
2. **An unknown `item_id` raised `NoMethodError` instead of failing validation.**
   `OrderItem#valid_quantity` called `item.available_quantity` without checking
   that `item` was there, so `POST /api/v1/orders` with a stale item id -- which
   the paired frontend can produce simply by leaving its item list open -- was a
   500. Fixed by guarding the validation, and by rejecting unknown items up front
   in `OrderProcessingService` with a clear message.
3. **A negative quantity put stock back on the shelf.** `quantity` had a presence
   check only, and `reduce_item_quantity` subtracted it, so `quantity: -3`
   validated and *added* three units. Fixed with a numericality validation.
4. **The discount factory could not build a discount.** It set
   `discount_percentage`, a column that does not exist (the column is
   `percentage`), so `create(:discount)` raised. Nothing in the suite called it,
   which is why the discount pricing rules -- the most interesting logic in the
   application -- had no test at all. Fixed, and the rules now have tests.
5. **`BaseController#resource` memoised into `@resources`.** The collection and
   the single record shared one instance variable. Latent rather than reachable
   through the routes as they stood, but a trap for the next reader. Fixed.

Two more were found by writing tests rather than by reading:

6. **`default from: ENV['EMAIL_DEFAULT_ADDRESS']` in `ApplicationMailer`** was
   read once at class load. With the variable unset it pinned `nil`, and every
   `deliver_now` raised `ArgumentError: SMTP From address may not be blank` --
   so the completion email, the last feature on the README's list, could not be
   sent by anyone who had not set that variable before boot. Fixed with a lambda
   and a fallback address.
7. **Adding RuboCop pulled `json 3.x` into the lockfile**, which removed the
   `quirks_mode:` keyword that Rails 6.0's JSON encoder passes, breaking every
   `render json:`. Caught by the request specs. `json` is now pinned to `~> 2.3`
   with a comment explaining why.

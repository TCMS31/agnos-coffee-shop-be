# Test, lint and query-count output

All of this is literal output from commands run on 2026-09-24, against
PostgreSQL 17 on a local test database. Nothing below was edited.

## Test suite

```console
$ bundle exec rspec --format documentation

OrderMailer
  is addressed to the customer
  falls back to a sender address when EMAIL_DEFAULT_ADDRESS is unset
  uses EMAIL_DEFAULT_ADDRESS when it is set
  has the expected subject
  greets the customer by name
  lists the ordered item and how many
  shows the total to two decimal places
  does not mark the order as notified

Customer
  associations
    is expected to have many orders dependent => destroy
  validations
    is expected to validate that :email cannot be empty/falsy
    is expected to validate that :name cannot be empty/falsy
    is expected to validate that :name is case-sensitively unique within the scope of :email
    rejects an address without a domain
    accepts a conventional address
  email normalisation
    strips and downcases on the way in
    treats a differently-cased address as the same customer
    exposes the same rule to callers that look customers up

Discount
  builds from the factory
  associations
    is expected to belong to item required: true
    is expected to belong to discount_with_item class_name => Item required: true
  validations
    is expected to validate that :percentage cannot be empty/falsy
    rejects a percentage over 100
    rejects a zero percentage
    refuses to pair an item with itself

Item
  associations
    is expected to have many order_items
    is expected to have many orders through order_items
    is expected to have many discounts dependent => destroy
    is expected to have many unlocked_discounts dependent => destroy
  validations
    is expected to validate that :name cannot be empty/falsy
    is expected to validate that :price cannot be empty/falsy
    rejects a negative price
    rejects negative stock
  deleting an item that has been ordered
    is refused rather than orphaning the order line
  deleting an item that only has discounts
    takes the discounts with it, both directions

OrderItem
  associations
    is expected to belong to order required: true
    is expected to belong to item required: true
  validations
    refuses to sell more than the shop has
    allows ordering exactly the remaining stock
    fails validation instead of raising when the item does not exist
    rejects a zero quantity
    rejects a negative quantity
  stock
    takes the ordered quantity off the shelf
    refreshes the in-memory item after the decrement
    refuses the write when the stock has gone since validation

Order
  takes its order items with it when destroyed
  associations
    is expected to belong to customer required: true
    is expected to have many order_items dependent => destroy
    is expected to have many items through order_items
  #notified?
    is false until the completion mail has gone out
    is true once the timestamp is set
  .recent_first
    returns the newest order first

Api::V1::Customers
  GET /api/v1/customers
    returns the customers under a "customers" key
  POST /api/v1/customers
    creates a customer
    rejects a malformed email
  DELETE /api/v1/customers/:id
    takes the customer orders with it

Api::V1::Discounts
  GET /api/v1/discounts
    lists the paired discounts
  POST /api/v1/discounts
    creates a paired discount
    rejects a percentage above 100
    rejects pairing an item with itself
  a created discount changes what an order costs
    is applied by the next order that buys the pair
  DELETE /api/v1/discounts/:id
    deletes the discount

Api::V1::Items
  GET /api/v1/items
    returns the menu under an "items" key
    exposes the fields the storefront renders
    paginates
  POST /api/v1/items
    creates an item
    rejects an item with no price
    rejects a negative price
    ignores attributes that are not permitted
  PATCH /api/v1/items/:id
    updates the item
  DELETE /api/v1/items/:id
    deletes an item nobody has ordered
    refuses to delete an item that appears on an order

Api::V1::OrderItems
  adds a line to an existing order and takes the stock
  returns 422, not 500, when the stock has gone
  lists order items

Api::V1::Orders
  POST /api/v1/orders
    creates the order
    responds 201
    returns the customer, the items and the total the frontend renders
    rejects a basket with no items
    rejects an unknown item with 422 rather than 500
    rejects an order for more than the shop has
    reports a missing customer block as a bad request
  GET /api/v1/orders
    returns the orders under an "orders" key
    paginates and reports the page in meta
    caps per_page so a client cannot ask for the whole table
    returns the newest order first
    loads customers and items without an N+1
  GET /api/v1/orders/:id
    returns the order
    returns a JSON 404 for an unknown id
  DELETE /api/v1/orders/:id
    deletes the order
    responds 204
  PATCH /api/v1/orders/:id
    is not routable

Health
  reports ok when the database answers
  reports unavailable when the database does not

OrderProcessingService
  a successful order
    creates the order
    reports success
    stores the tax-inclusive total
    prices a mixed basket
    applies a paired discount
    takes the stock
    schedules the completion notification
    schedules it for ten minutes out
    reuses a returning customer rather than duplicating them
    matches a returning customer whose address is cased differently
  a rejected order
    refuses an empty basket
    refuses a nil basket
    refuses an unknown item
    refuses an invalid email
    refuses to oversell
    leaves no order behind when a later line fails
    gives back the stock taken by the lines that did succeed
    does not schedule a notification
  query count
    does not grow the item/discount queries with basket size
  rule injection
    prices with the calculator it is handed

Pricing::Calculator
  prices an empty basket as zero
  tax
    adds the item tax rate to the shelf price
    multiplies by quantity
    taxes each item at its own rate
  paired discounts
    leaves the price alone when the paired item is absent
    takes the percentage off when both items are in the basket
    is directional: the paired item is not itself discounted
    applies the discount to the taxed price, not the shelf price
    applies at most one discount per line
  rounding
    rounds every line to whole cents so the total matches the visible lines
  the rule pipeline
    runs exactly the rules it is given
    accepts a rule the application does not ship

OrderCompletionJob
  sends the completion email
  records when the notification went out
  does not send twice if the job is retried
  does nothing when the order has been deleted

Finished in 0.77232 seconds (files took 0.68605 seconds to load)
129 examples, 0 failures

```

## Linter

```console
$ bundle exec rubocop
Inspecting 85 files
.....................................................................................

85 files inspected, no offenses detected
```

## Query counts

Measured with an `ActiveSupport::Notifications.subscribe('sql.active_record')`
counter, run once against the code at commit `9d8516a` (extracted with
`git archive`) and once against this branch, both pointed at the same seeded
database.

### Placing one order with seven distinct lines

```console
# before -- app/services/order_processing_service.rb at 9d8516a
lines=7 total_sql=35 item_selects=7 discount_selects=7

# after
lines=7 total_sql=23 item_selects=1 discount_selects=1
```

Item and discount lookups no longer scale with basket size: they were two
SELECTs per line (one to resolve `order_item.item`, one for `item.discounts`),
and they are now two in total no matter how long the order is.

### Serializing the orders index

`OrderSerializer` renders the customer and the ordered items, so the old
unpaginated `Order.all` issued two extra queries per order.

```console
# before -- Order.all.order(created_at: :desc), 27 orders in the table
orders_serialized=27 sql_queries=55

# after -- Order.includes(:customer, :items), capped at 25 per page
orders_serialized=25 sql_queries=4
```

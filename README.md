# A day at a coffee shop!
This project is a Restful architecture based rails application to handle the operations of a coffee shop.

### Features (APIs)
- Manage items for the coffee shop.
- Manage customers (recurring and new).
- Manage Orders for customers.
- Manage Taxations on each item.
- Apply Discounts on pair of items when bought together. (Assumptions in seed)
- Notifications to customers for order completeion using email.

### Assumptions
- With each order, information of customer and order_items will be sent in request.
- Discounts will be applied only if items are bought together in one order.
- Tax addition will happen per item basis.

## Project structure

| Name                          | Description                               |
| ------------------------------|------------------------------------------ |
| app/controllers/api/v1        | Project APIs                              |
| app/models/                   | Models                                    |
| app/serializers               | Serializers for user views                |
| app/services                  | Business logic for billing process        |
| app/sidekiq                   | background jobs                           |
| app/mailers                   | Mailers for order notifications           |
| spec                          | Test cases using Rspec, shoulda matchers  |
| tmp/letter_opener             | Rendered mails in development environment by letter opener|



### DEPENDENCIES
- Ruby 2.7.5
- Rails 6.0.6

## PROJECT SETUP

### Install required dependencies
This project was built using Ruby on Rails, it has a variety of dependencies in the form of "ruby gems".
See ruby version in gemfile.

Once you have ruby installed, you will need the bundler gem. To install bundler, simply run:

```
gem install bundler
```

After bundler is installed, run the following command from the root directory of the application (you may need to install some dependencies):

```
bundle install
```

Amazing! Now all of those sweet packages we use to make this application work should be installed.

### Configure database connection
Run the following commands in terminal from the root of the project:

```
rake db:setup
```

### Define the following environment variables

```
GMAIL_USERNAME
GMAIL_PASSWORD
HOST
EMAIL_DEFAULT_ADDRESS
```

### Seed data
Run the following command in termincal from the root of the project to add initial data.
```
rails db:seed
```
Hurray! the project is ready to run.


## If I had extra time

> Improvements in UI/UX

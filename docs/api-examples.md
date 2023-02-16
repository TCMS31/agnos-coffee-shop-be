# Captured API output

Every block below is real terminal output, captured on 2026-09-24 against the
app running locally on port 8531 (`bundle exec puma -C config/puma.rb`) with the
database seeded by `rails db:seed`. Nothing here is hand-written.

Base URL: `http://localhost:8531/api/v1` (all paths below are relative to it).

The two totals worth checking by hand:

* **Order 1** — Flat White (3.80 @ 5% tax = 3.99) plus Butter Croissant
  (3.10 @ 12.5% tax = 3.4875, then 20% off because a Flat White is in the same
  basket = 2.79). Total **6.78**.
* **Order 2** — two Espressos (2.50 @ 5% tax = 2.625, rounded to 2.63 each).
  Total **5.25**. The croissant discount does not apply: no croissant.

## 1. The menu (paginated)

```console
$ curl -s -X GET /items?per_page=3
{
  "items": [
    {
      "id": 7,
      "name": "Blueberry Muffin",
      "price": 2.95,
      "tax_rate": 12.5,
      "available_quantity": 35
    },
    {
      "id": 6,
      "name": "Avocado Sourdough",
      "price": 7.95,
      "tax_rate": 12.5,
      "available_quantity": 30
    },
    {
      "id": 5,
      "name": "Almond Danish",
      "price": 3.6,
      "tax_rate": 12.5,
      "available_quantity": 25
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 3,
    "total_count": 7,
    "total_pages": 3
  }
}
HTTP 200
```

## 2. The paired discounts (this endpoint used to raise "missing controller")

```console
$ curl -s -X GET /discounts
{
  "discounts": [
    {
      "id": 3,
      "item_id": 7,
      "discount_with_item_id": 3,
      "percentage": 10.0
    },
    {
      "id": 2,
      "item_id": 5,
      "discount_with_item_id": 1,
      "percentage": 15.0
    },
    {
      "id": 1,
      "item_id": 4,
      "discount_with_item_id": 2,
      "percentage": 20.0
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total_count": 3,
    "total_pages": 1
  }
}
HTTP 200
```

## 3. Placing an order: a Flat White (id 2) and a Butter Croissant (id 4)

```console
$ curl -s -X POST /orders -H 'Content-Type: application/json' -d '{"customer":{"name":"Ada Lovelace","email":"ada@example.com"},"order_items":[{"item_id":2,"quantity":1},{"item_id":4,"quantity":1}]}'
{
  "id": 1,
  "total_amount": 6.78,
  "created_at": "2026-09-24T23:54:54.882Z",
  "customer": {
    "id": 1,
    "name": "Ada Lovelace",
    "email": "ada@example.com"
  },
  "items": [
    {
      "id": 2,
      "name": "Flat White",
      "price": 3.8,
      "tax_rate": 5.0,
      "available_quantity": 149
    },
    {
      "id": 4,
      "name": "Butter Croissant",
      "price": 3.1,
      "tax_rate": 12.5,
      "available_quantity": 39
    }
  ]
}
HTTP 201
```

## 4. Stock was taken (Flat White 150 -> 149, Butter Croissant 40 -> 39)

```console
$ curl -s -X GET /items/2
{
  "id": 2,
  "name": "Flat White",
  "price": 3.8,
  "tax_rate": 5.0,
  "available_quantity": 149
}
HTTP 200

$ curl -s -X GET /items/4
{
  "id": 4,
  "name": "Butter Croissant",
  "price": 3.1,
  "tax_rate": 12.5,
  "available_quantity": 39
}
HTTP 200
```

## 5. The same customer orders again -- no duplicate customer row

```console
$ curl -s -X POST /orders -H 'Content-Type: application/json' -d '{"customer":{"name":"Ada Lovelace","email":"  ADA@Example.COM "},"order_items":[{"item_id":1,"quantity":2}]}'
{
  "id": 2,
  "total_amount": 5.25,
  "created_at": "2026-09-24T23:54:54.969Z",
  "customer": {
    "id": 1,
    "name": "Ada Lovelace",
    "email": "ada@example.com"
  },
  "items": [
    {
      "id": 1,
      "name": "Espresso",
      "price": 2.5,
      "tax_rate": 5.0,
      "available_quantity": 198
    }
  ]
}
HTTP 201

$ curl -s -X GET /customers
{
  "customers": [
    {
      "id": 1,
      "name": "Ada Lovelace",
      "email": "ada@example.com"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total_count": 1,
    "total_pages": 1
  }
}
HTTP 200
```

## 6. Error paths

### More than the shop has

```console
$ curl -s -X POST /orders -H 'Content-Type: application/json' -d '{"customer":{"name":"Ada Lovelace","email":"ada@example.com"},"order_items":[{"item_id":5,"quantity":9999}]}'
{
  "errors": [
    "We don't have enough quantity for the items!"
  ]
}
HTTP 422
```

### An item that does not exist

```console
$ curl -s -X POST /orders -H 'Content-Type: application/json' -d '{"customer":{"name":"Ada Lovelace","email":"ada@example.com"},"order_items":[{"item_id":999999,"quantity":1}]}'
{
  "errors": [
    "One or more of the requested items do not exist."
  ]
}
HTTP 422
```

### An empty basket

```console
$ curl -s -X POST /orders -H 'Content-Type: application/json' -d '{"customer":{"name":"Ada Lovelace","email":"ada@example.com"},"order_items":[]}'
{
  "errors": [
    "Order items are required!"
  ]
}
HTTP 422
```

### No customer block at all

```console
$ curl -s -X POST /orders -H 'Content-Type: application/json' -d '{"order_items":[{"item_id":1,"quantity":1}]}'
{
  "errors": [
    "Missing required parameter: customer"
  ]
}
HTTP 400
```

### A malformed email

```console
$ curl -s -X POST /customers -H 'Content-Type: application/json' -d '{"name":"Nope","email":"nope"}'
{
  "errors": [
    "Email is invalid"
  ]
}
HTTP 422
```

### An id that does not exist

```console
$ curl -s -X GET /orders/999999
{
  "errors": [
    "Record not found!"
  ]
}
HTTP 404
```

### Deleting an item that appears on an order

```console
$ curl -s -X DELETE /items/2
{
  "errors": [
    "Cannot delete record because dependent order items exist"
  ]
}
HTTP 422
```

### A discount that pairs an item with itself

```console
$ curl -s -X POST /discounts -H 'Content-Type: application/json' -d '{"item_id":1,"discount_with_item_id":1,"percentage":10}'
{
  "errors": [
    "Discount with item must be a different item"
  ]
}
HTTP 422
```

## 7. Orders list, newest first, with pagination meta

```console
$ curl -s -X GET /orders?per_page=2
{
  "orders": [
    {
      "id": 2,
      "total_amount": 5.25,
      "created_at": "2026-09-24T23:54:54.969Z",
      "customer": {
        "id": 1,
        "name": "Ada Lovelace",
        "email": "ada@example.com"
      },
      "items": [
        {
          "id": 1,
          "name": "Espresso",
          "price": 2.5,
          "tax_rate": 5.0,
          "available_quantity": 198
        }
      ]
    },
    {
      "id": 1,
      "total_amount": 6.78,
      "created_at": "2026-09-24T23:54:54.882Z",
      "customer": {
        "id": 1,
        "name": "Ada Lovelace",
        "email": "ada@example.com"
      },
      "items": [
        {
          "id": 2,
          "name": "Flat White",
          "price": 3.8,
          "tax_rate": 5.0,
          "available_quantity": 149
        },
        {
          "id": 4,
          "name": "Butter Croissant",
          "price": 3.1,
          "tax_rate": 12.5,
          "available_quantity": 39
        }
      ]
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 2,
    "total_count": 2,
    "total_pages": 1
  }
}
HTTP 200
```


# Database Architecture

---

## Design Overview

The original flat `sales` table (16 columns, 20,000 rows) has been decomposed into **10 relational tables** in **Third Normal Form (3NF)**:

| Layer | Tables | Purpose |
|---|---|---|
| **Lookup** | `shipping_methods`, `payment_methods`, `order_statuses`, `product_categories`, `addon_types` | Controlled vocabularies — eliminates typos and inconsistencies |
| **Entities** | `customers`, `products` | One row per real-world entity — stored once |
| **Transactions** | `orders`, `order_items`, `order_addons` | Normalized order data with line-item granularity |
| **History** | `loyalty_history` | Tracks loyalty status changes over time |

Three pre-built views provide query-ready datasets: `v_order_summary`, `v_customer_analytics`, `v_product_performance`.

---

## Why 3NF

| Problem in Flat Table | How Normalization Fixes It |
|---|---|
| Customer demographics repeated on every row | Stored once in `customers` |
| `Paypal` and `PayPal` coexist | Lookup table with UNIQUE constraint — one spelling only |
| No referential integrity | Foreign keys enforce valid references |
| Comma-separated add-ons in TEXT field | Each add-on is its own row in `order_addons` |
| `total_price` excluded add-ons (undocumented) | `line_total` is a generated column; `v_order_summary.order_revenue` computes the true total |
| 2,270 customers with changing loyalty status | `loyalty_history` tracks the full timeline |

---

## Entity Relationship Diagram

```
┌─────────────────────┐
│  product_categories  │
│─────────────────────│
│ PK  category_id     │
│     category_name    │
└──────────┬──────────┘
           │ 1:M
┌──────────┴──────────┐         ┌─────────────────────┐
│      products       │         │    addon_types       │
│─────────────────────│         │─────────────────────│
│ PK  product_id      │         │ PK  addon_type_id    │
│     sku             │         │     addon_name       │
│ FK  category_id     │         └──────────┬──────────┘
│     unit_price      │                    │ 1:M
└──────────┬──────────┘         ┌──────────┴──────────┐
           │ 1:M                │    order_addons      │
┌──────────┴──────────┐        │─────────────────────│
│    order_items      │   1:M  │ PK  addon_id         │
│─────────────────────│◄──────│ FK  order_item_id    │
│ PK  order_item_id   │        │ FK  addon_type_id    │
│ FK  order_id        │        │     addon_price      │
│ FK  product_id      │        └─────────────────────┘
│     quantity        │
│     unit_price      │
│     line_total (gen)│
│     rating          │
└──────────┬──────────┘
           │ M:1
┌──────────┴──────────┐
│       orders        │──FK──► order_statuses
│─────────────────────│──FK──► payment_methods
│ PK  order_id        │──FK──► shipping_methods
│ FK  customer_id     │
│     purchase_date   │
└──────────┬──────────┘
           │ M:1
┌──────────┴──────────┐
│     customers       │
│─────────────────────│
│ PK  customer_id     │
│     age, gender     │
│     current_loyalty │
│     loyalty_start_dt│
└──────────┬──────────┘
           │ 1:M
┌──────────┴──────────┐
│  loyalty_history    │
│─────────────────────│
│ PK  history_id      │
│ FK  customer_id     │
│     status          │
│     effective_date  │
└─────────────────────┘
```

### ON DELETE Rules

| Relationship | Rule | Reason |
|---|---|---|
| orders → customers | RESTRICT | Cannot delete a customer with orders |
| order_items → orders | CASCADE | Deleting an order removes its items |
| order_addons → order_items | CASCADE | Deleting an item removes its add-ons |
| order_items → products | RESTRICT | Cannot delete a sold product |
| loyalty_history → customers | CASCADE | History follows the customer |
| All lookups | RESTRICT | Cannot remove values while in use |

---

## Key Design Decisions

**Surrogate keys on `products`:** The raw data has SKUs shared across product types (e.g., SKU1004 = Smartphone at $791 and Laptop at $932). A surrogate `product_id` resolves this; UNIQUE constraint on `(sku, category_id, unit_price)`.

**Generated column for `line_total`:** `GENERATED ALWAYS AS (unit_price * quantity) STORED` — calculated once on write, guaranteed accurate, indexable.

**Lookup tables instead of ENUMs:** Adding a new payment method or shipping type is an INSERT, not an ALTER TABLE.

**TINYINT keys on lookups:** 1 byte per FK reference instead of 30+ bytes for VARCHAR strings. Faster joins, smaller indexes.

---

## Performance

Key composite indexes beyond the default FK indexes:

| Index | Table | Columns | Supports |
|---|---|---|---|
| `idx_orders_date_status` | orders | `(purchase_date, status_id)` | Monthly revenue queries |
| `idx_orders_customer` | orders | `(customer_id)` | Customer order history |
| `idx_items_product` | order_items | `(product_id)` | Product performance |
| `idx_customers_loyalty` | customers | `(current_loyalty)` | Loyalty reports |
| `idx_loyalty_customer` | loyalty_history | `(customer_id, effective_date)` | Enrollment timeline |

---

## Scalability

| Change Needed | Impact |
|---|---|
| New product category | INSERT into `product_categories` |
| New payment method | INSERT into `payment_methods` |
| Multi-item orders | Already supported via `order_items` |
| Inventory tracking | New table with FK to `products` — nothing else changes |
| Returns / refunds | New table — no existing schema changes |

---

## Analytical Views

**`v_order_summary`** — Order-level totals: product revenue, add-on revenue, full order revenue. Pre-joins all lookup tables.

**`v_customer_analytics`** — Customer-level aggregates: total orders, completion rate, total spent, AOV, first/last purchase, lifespan.

**`v_product_performance`** — Product-level metrics: orders, units sold, revenue, avg price, avg rating, completion rate.

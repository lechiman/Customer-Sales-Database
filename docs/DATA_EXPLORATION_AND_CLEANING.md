# Data Exploration & Cleaning

---

## 1. Dataset Overview

| Metric | Value |
|---|---|
| **Source** | `Electronic_sales_Sep2023-Sep2024.csv` |
| **Rows** | 20,000 transactions |
| **Columns** | 16 fields |
| **Date range** | Sep 24, 2023 – Sep 23, 2024 |
| **Unique customers** | 12,136 |
| **Product categories** | 5 (Smartphone, Laptop, Tablet, Smartwatch, Headphones) |

---

## 2. Issues Found

### Inconsistent Values

| Field | Issue |
|---|---|
| **Payment Method** | `Paypal` (2,514 rows) vs `PayPal` (3,284 rows) — same method, two spellings |
| **Gender** | 1 row contains `#N/A` instead of Male/Female |

### Loyalty Status Changes

2,270 customers appear with both `Yes` and `No` across transactions — they enrolled mid-year. Not an error, but requires intentional handling: track history in a separate table, store most recent status on the customer record.

### Missing Values

| Field | Missing | Action |
|---|---|---|
| **Add-ons Purchased** | 4,868 (24.3%) | Expected — not every order has add-ons. Store as NULL. |
| **All other fields** | 0 | Fully populated. |

### Price Formula Discovery

```
total_price = unit_price × quantity       ← TRUE for 100% of rows
total_price includes addon_total          ← FALSE
```

`total_price` is the product subtotal only. Add-on revenue is separate. **True order revenue = total_price + addon_total.** The original data dictionary was wrong — this is the kind of silent error that corrupts every downstream report.

### Other Checks

- 0 exact duplicate rows
- All dates in `YYYY-MM-DD` format — no parsing needed

---

## 3. Cleaning Actions

| Action | Detail |
|---|---|
| **Standardize PayPal** | `Paypal` → `PayPal` (proper casing) |
| **Fix #N/A gender** | Check if customer has valid gender on other transactions; carry forward or set NULL |
| **Null handling** | Empty add-ons → NULL. Enforce `addon_total = 0` when no add-ons. |
| **Validate prices** | `unit_price > 0`, `quantity ≥ 1`, `total_price = unit_price × quantity` (100% pass) |
| **Resolve loyalty** | Store current status on `customers`, full history on `loyalty_history` |

---

## 4. Validation Queries (Post-Load)

```sql
-- Revenue consistency: line_total must equal unit_price × quantity
SELECT order_item_id, unit_price, quantity, line_total
FROM order_items
WHERE ABS(line_total - (unit_price * quantity)) > 0.01;

-- Orphan check: all FKs should resolve
SELECT
    (SELECT COUNT(*) FROM orders o LEFT JOIN customers c
     ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL)
     AS orphan_orders,
    (SELECT COUNT(*) FROM order_items oi LEFT JOIN orders o
     ON oi.order_id = o.order_id WHERE o.order_id IS NULL)
     AS orphan_items;
-- All values should be 0

-- No unstandardized payment values
SELECT DISTINCT payment_type FROM payment_methods ORDER BY payment_type;
-- Expected: Bank Transfer, Cash, Credit Card, Debit Card, PayPal
```

---

## 5. Why This Matters

- The `Paypal` vs `PayPal` split would **undercount PayPal transactions by 43%** in any report filtering on the exact string.
- Summing `total_price` as "total revenue" **systematically undercounts** by the entire add-on amount across 15,132 transactions.
- 2,270 customers with dual loyalty flags would be **double-counted** in both segments by a simple GROUP BY.

These aren't edge cases — they're the normal state of business data that hasn't been cleaned and normalized.

-- =====================================================
-- EXECUTIVE KPI QUERIES
-- Electronic Sales Database (Normalized 3NF Schema)
-- =====================================================
-- These queries are designed to run against the normalized
-- schema defined in schema/001_create_database.sql.
-- They leverage the pre-built views (v_order_summary,
-- v_customer_analytics, v_product_performance) where
-- appropriate, and join across normalized tables directly
-- for queries that need finer control.
-- =====================================================

USE electronic_sales_db;


-- =====================================================
-- SECTION 1: REVENUE METRICS
-- =====================================================


-- 1.1  Total Revenue (Completed Orders Only)
-- Measures: gross revenue including product totals + add-on revenue.
-- Uses v_order_summary which pre-computes order_revenue.

SELECT
    FORMAT(SUM(order_revenue), 2)   AS total_revenue,
    FORMAT(SUM(product_total), 2)   AS product_revenue,
    FORMAT(SUM(addon_total), 2)     AS addon_revenue,
    COUNT(*)                        AS completed_orders
FROM v_order_summary
WHERE order_status = 'Completed';


-- 1.2  Monthly Revenue Trend (Sep 2023 – Sep 2024)
-- Measures: revenue trajectory month over month.
-- Includes order count and AOV for context.

SELECT
    DATE_FORMAT(purchase_date, '%Y-%m')     AS month,
    FORMAT(SUM(order_revenue), 2)           AS revenue,
    COUNT(*)                                AS orders,
    FORMAT(ROUND(AVG(order_revenue), 2), 2) AS avg_order_value
FROM v_order_summary
WHERE order_status = 'Completed'
GROUP BY DATE_FORMAT(purchase_date, '%Y-%m')
ORDER BY month;


-- 1.3  Revenue by Product Category
-- Measures: which product lines drive the most revenue.
-- Joins order_items → products → product_categories for accuracy.

SELECT
    pc.category_name                        AS product_category,
    FORMAT(SUM(oi.line_total), 2)           AS revenue,
    SUM(oi.quantity)                         AS units_sold,
    COUNT(DISTINCT o.order_id)              AS orders,
    FORMAT(ROUND(AVG(oi.line_total), 2), 2) AS avg_line_value
FROM order_items oi
JOIN orders o           ON oi.order_id    = o.order_id
JOIN order_statuses os  ON o.status_id    = os.status_id
JOIN products p         ON oi.product_id  = p.product_id
JOIN product_categories pc ON p.category_id = pc.category_id
WHERE os.status_name = 'Completed'
GROUP BY pc.category_name
ORDER BY SUM(oi.line_total) DESC;


-- 1.4  Revenue by Payment Method
-- Measures: payment channel contribution to total revenue.

SELECT
    pm.payment_type                         AS payment_method,
    FORMAT(SUM(vs.order_revenue), 2)        AS revenue,
    COUNT(*)                                AS orders,
    ROUND(
        SUM(vs.order_revenue) * 100.0
        / SUM(SUM(vs.order_revenue)) OVER (), 1
    )                                       AS pct_of_total
FROM v_order_summary vs
JOIN orders o           ON vs.order_id  = o.order_id
JOIN payment_methods pm ON o.payment_id = pm.payment_id
WHERE vs.order_status = 'Completed'
GROUP BY pm.payment_type
ORDER BY SUM(vs.order_revenue) DESC;


-- 1.5  Revenue by Shipping Type
-- Measures: revenue distribution across fulfillment methods.

SELECT
    sm.shipping_type                        AS shipping_method,
    FORMAT(SUM(vs.order_revenue), 2)        AS revenue,
    COUNT(*)                                AS orders,
    ROUND(
        SUM(vs.order_revenue) * 100.0
        / SUM(SUM(vs.order_revenue)) OVER (), 1
    )                                       AS pct_of_total
FROM v_order_summary vs
JOIN orders o            ON vs.order_id   = o.order_id
JOIN shipping_methods sm ON o.shipping_id = sm.shipping_id
WHERE vs.order_status = 'Completed'
GROUP BY sm.shipping_type
ORDER BY SUM(vs.order_revenue) DESC;


-- =====================================================
-- SECTION 2: CUSTOMER METRICS
-- =====================================================


-- 2.1  Total Customers
-- Measures: unique customer count with order activity.

SELECT
    COUNT(DISTINCT customer_id)     AS total_customers,
    COUNT(DISTINCT CASE
        WHEN total_orders > 1 THEN customer_id
    END)                            AS repeat_customers,
    COUNT(DISTINCT CASE
        WHEN total_orders = 1 THEN customer_id
    END)                            AS one_time_buyers
FROM v_customer_analytics;


-- 2.2  New vs Returning Customers by Month
-- Measures: acquisition vs retention trajectory.
-- A customer is "new" in the month of their first purchase.

WITH first_purchases AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(purchase_date), '%Y-%m') AS acquisition_month
    FROM orders
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT
        o.customer_id,
        DATE_FORMAT(o.purchase_date, '%Y-%m') AS activity_month
    FROM orders o
    JOIN order_statuses os ON o.status_id = os.status_id
    WHERE os.status_name = 'Completed'
    GROUP BY o.customer_id, DATE_FORMAT(o.purchase_date, '%Y-%m')
)
SELECT
    ma.activity_month                                       AS month,
    COUNT(DISTINCT ma.customer_id)                          AS active_customers,
    COUNT(DISTINCT CASE
        WHEN ma.activity_month = fp.acquisition_month
        THEN ma.customer_id
    END)                                                    AS new_customers,
    COUNT(DISTINCT CASE
        WHEN ma.activity_month != fp.acquisition_month
        THEN ma.customer_id
    END)                                                    AS returning_customers
FROM monthly_activity ma
JOIN first_purchases fp ON ma.customer_id = fp.customer_id
GROUP BY ma.activity_month
ORDER BY ma.activity_month;


-- 2.3  Average Order Value (AOV)
-- Measures: mean revenue per completed order.

SELECT
    FORMAT(ROUND(AVG(order_revenue), 2), 2)   AS overall_aov,
    FORMAT(ROUND(AVG(product_total), 2), 2)   AS product_aov,
    FORMAT(ROUND(AVG(addon_total), 2), 2)     AS addon_aov
FROM v_order_summary
WHERE order_status = 'Completed';


-- 2.4  Customer Lifetime Value (CLV)
-- Measures: total and average revenue per customer.
-- Segments by value tier for prioritization.

WITH customer_value AS (
    SELECT
        customer_id,
        total_spent,
        completed_orders,
        avg_order_value,
        customer_lifespan_days,
        CASE
            WHEN total_spent >= 10000 THEN 'VIP ($10K+)'
            WHEN total_spent >= 5000  THEN 'High Value ($5K–$10K)'
            WHEN total_spent >= 2000  THEN 'Mid Value ($2K–$5K)'
            WHEN total_spent >= 500   THEN 'Regular ($500–$2K)'
            ELSE 'Low Value (<$500)'
        END AS value_tier
    FROM v_customer_analytics
    WHERE completed_orders > 0
)
SELECT
    value_tier,
    COUNT(*)                                    AS customers,
    FORMAT(ROUND(AVG(total_spent), 2), 2)       AS avg_clv,
    FORMAT(ROUND(SUM(total_spent), 2), 2)       AS segment_revenue,
    ROUND(
        SUM(total_spent) * 100.0
        / SUM(SUM(total_spent)) OVER (), 1
    )                                           AS pct_of_total_revenue,
    ROUND(AVG(completed_orders), 1)             AS avg_orders,
    ROUND(AVG(customer_lifespan_days), 0)       AS avg_lifespan_days
FROM customer_value
GROUP BY value_tier
ORDER BY AVG(total_spent) DESC;


-- 2.5  Loyalty vs Non-Loyalty Revenue Comparison
-- Measures: ROI of the loyalty program.

SELECT
    c.current_loyalty                           AS loyalty_status,
    COUNT(DISTINCT c.customer_id)               AS customers,
    COUNT(DISTINCT o.order_id)                  AS orders,
    FORMAT(SUM(vs.order_revenue), 2)            AS total_revenue,
    FORMAT(ROUND(AVG(vs.order_revenue), 2), 2)  AS avg_order_value,
    FORMAT(ROUND(
        SUM(vs.order_revenue)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2
    ), 2)                                       AS revenue_per_customer
FROM customers c
JOIN orders o           ON c.customer_id = o.customer_id
JOIN v_order_summary vs ON o.order_id    = vs.order_id
WHERE vs.order_status = 'Completed'
GROUP BY c.current_loyalty
ORDER BY SUM(vs.order_revenue) DESC;


-- =====================================================
-- SECTION 3: OPERATIONAL METRICS
-- =====================================================


-- 3.1  Order Cancellation Rate
-- Measures: what percentage of orders are cancelled.
-- Broken down by month for trend visibility.

SELECT
    DATE_FORMAT(o.purchase_date, '%Y-%m')       AS month,
    COUNT(*)                                    AS total_orders,
    SUM(CASE WHEN os.status_name = 'Cancelled'
        THEN 1 ELSE 0 END)                     AS cancelled,
    SUM(CASE WHEN os.status_name = 'Completed'
        THEN 1 ELSE 0 END)                     AS completed,
    ROUND(
        SUM(CASE WHEN os.status_name = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                           AS cancellation_rate_pct
FROM orders o
JOIN order_statuses os ON o.status_id = os.status_id
GROUP BY DATE_FORMAT(o.purchase_date, '%Y-%m')
ORDER BY month;


-- 3.2  Average Units per Order
-- Measures: basket depth (items per transaction).

SELECT
    ROUND(AVG(item_count), 2)   AS avg_items_per_order,
    ROUND(AVG(total_qty), 2)    AS avg_units_per_order,
    MAX(total_qty)              AS max_units_single_order
FROM (
    SELECT
        oi.order_id,
        COUNT(oi.order_item_id) AS item_count,
        SUM(oi.quantity)        AS total_qty
    FROM order_items oi
    JOIN orders o          ON oi.order_id  = o.order_id
    JOIN order_statuses os ON o.status_id  = os.status_id
    WHERE os.status_name = 'Completed'
    GROUP BY oi.order_id
) basket;


-- 3.3  Add-on Attachment Rate
-- Measures: what fraction of orders include at least one add-on.
-- Also shows add-on revenue contribution.

WITH order_addons_agg AS (
    SELECT
        oi.order_id,
        SUM(oa.addon_price) AS addon_revenue
    FROM order_items oi
    JOIN order_addons oa ON oi.order_item_id = oa.order_item_id
    GROUP BY oi.order_id
)
SELECT
    COUNT(DISTINCT o.order_id)                              AS total_completed_orders,
    COUNT(DISTINCT oaa.order_id)                            AS orders_with_addons,
    ROUND(
        COUNT(DISTINCT oaa.order_id) * 100.0
        / NULLIF(COUNT(DISTINCT o.order_id), 0), 1
    )                                                       AS attachment_rate_pct,
    FORMAT(COALESCE(SUM(oaa.addon_revenue), 0), 2)          AS total_addon_revenue,
    FORMAT(ROUND(AVG(oaa.addon_revenue), 2), 2)             AS avg_addon_per_order
FROM orders o
JOIN order_statuses os ON o.status_id = os.status_id
LEFT JOIN order_addons_agg oaa ON o.order_id = oaa.order_id
WHERE os.status_name = 'Completed';


-- 3.4  Top 10 Best-Selling Products
-- Measures: product ranking by revenue, with supporting metrics.

SELECT
    product_type,
    sku,
    total_revenue       AS revenue,
    units_sold,
    completed_orders,
    avg_unit_price,
    avg_rating
FROM v_product_performance
ORDER BY total_revenue DESC
LIMIT 10;


-- 3.5  Top 5 Highest Revenue-Generating Customers
-- Measures: individual customer contribution.

SELECT
    customer_id,
    current_loyalty     AS loyalty_status,
    age,
    gender,
    total_spent         AS lifetime_revenue,
    completed_orders,
    avg_order_value,
    first_purchase,
    last_purchase,
    customer_lifespan_days
FROM v_customer_analytics
WHERE completed_orders > 0
ORDER BY total_spent DESC
LIMIT 5;


-- =====================================================
-- END OF EXECUTIVE KPI QUERIES
-- =====================================================

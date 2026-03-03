-- =====================================================
-- ADVANCED ANALYTICAL QUERIES
-- Electronic Sales Database (Normalized 3NF Schema)
-- =====================================================
-- These queries go beyond standard KPIs to deliver
-- segmentation, cohort analysis, and trend detection.
-- They use window functions, CTEs, CASE expressions,
-- and multi-table JOINs across the normalized schema.
-- =====================================================

USE electronic_sales_db;


-- =====================================================
-- 1.  REVENUE BY AGE GROUP SEGMENTATION
-- =====================================================
-- Segments customers into generational cohorts and
-- compares revenue contribution, AOV, and loyalty rate.

SELECT
    CASE
        WHEN c.age < 25 THEN 'Gen Z (18–24)'
        WHEN c.age < 35 THEN 'Millennials (25–34)'
        WHEN c.age < 45 THEN 'Gen X (35–44)'
        WHEN c.age < 55 THEN 'Boomers (45–54)'
        WHEN c.age < 65 THEN 'Seniors (55–64)'
        ELSE 'Elderly (65+)'
    END                                                 AS age_group,
    COUNT(DISTINCT c.customer_id)                       AS customers,
    COUNT(DISTINCT o.order_id)                          AS orders,
    FORMAT(SUM(vs.order_revenue), 2)                    AS total_revenue,
    ROUND(
        SUM(vs.order_revenue) * 100.0
        / SUM(SUM(vs.order_revenue)) OVER (), 1
    )                                                   AS pct_of_revenue,
    FORMAT(ROUND(AVG(vs.order_revenue), 2), 2)          AS avg_order_value,
    ROUND(
        COUNT(DISTINCT CASE WHEN c.current_loyalty = 'Yes'
            THEN c.customer_id END) * 100.0
        / NULLIF(COUNT(DISTINCT c.customer_id), 0), 1
    )                                                   AS loyalty_rate_pct
FROM customers c
JOIN orders o           ON c.customer_id = o.customer_id
JOIN v_order_summary vs ON o.order_id    = vs.order_id
WHERE vs.order_status = 'Completed'
GROUP BY age_group
ORDER BY SUM(vs.order_revenue) DESC;


-- =====================================================
-- 2.  REVENUE BY GENDER
-- =====================================================
-- Compares male vs female customers on revenue, AOV,
-- and average rating given.

SELECT
    c.gender,
    COUNT(DISTINCT c.customer_id)                       AS customers,
    COUNT(DISTINCT o.order_id)                          AS orders,
    FORMAT(SUM(vs.order_revenue), 2)                    AS total_revenue,
    FORMAT(ROUND(AVG(vs.order_revenue), 2), 2)          AS avg_order_value,
    ROUND(AVG(oi.rating), 2)                            AS avg_rating
FROM customers c
JOIN orders o           ON c.customer_id  = o.customer_id
JOIN v_order_summary vs ON o.order_id     = vs.order_id
JOIN order_items oi     ON o.order_id     = oi.order_id
WHERE vs.order_status = 'Completed'
  AND c.gender IS NOT NULL
GROUP BY c.gender
ORDER BY SUM(vs.order_revenue) DESC;


-- =====================================================
-- 3.  MONTHLY COHORT RETENTION ANALYSIS
-- =====================================================
-- Groups customers by their acquisition month and tracks
-- how many return in subsequent months (M+1, M+2, …).
-- This is the standard SaaS/retail cohort retention format.

WITH cohorts AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(purchase_date), '%Y-%m') AS cohort_month
    FROM orders
    GROUP BY customer_id
),
activity AS (
    SELECT DISTINCT
        o.customer_id,
        DATE_FORMAT(o.purchase_date, '%Y-%m') AS activity_month
    FROM orders o
    JOIN order_statuses os ON o.status_id = os.status_id
    WHERE os.status_name = 'Completed'
),
retention AS (
    SELECT
        co.cohort_month,
        a.activity_month,
        PERIOD_DIFF(
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(a.activity_month, '-01'), '%Y-%m-%d')),
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(co.cohort_month, '-01'), '%Y-%m-%d'))
        ) AS months_since_acquisition,
        COUNT(DISTINCT a.customer_id) AS active_customers
    FROM cohorts co
    JOIN activity a ON co.customer_id = a.customer_id
    GROUP BY co.cohort_month, a.activity_month
)
SELECT
    cohort_month,
    MAX(CASE WHEN months_since_acquisition = 0 THEN active_customers END) AS M0,
    MAX(CASE WHEN months_since_acquisition = 1 THEN active_customers END) AS M1,
    MAX(CASE WHEN months_since_acquisition = 2 THEN active_customers END) AS M2,
    MAX(CASE WHEN months_since_acquisition = 3 THEN active_customers END) AS M3,
    MAX(CASE WHEN months_since_acquisition = 4 THEN active_customers END) AS M4,
    MAX(CASE WHEN months_since_acquisition = 5 THEN active_customers END) AS M5,
    MAX(CASE WHEN months_since_acquisition = 6 THEN active_customers END) AS M6
FROM retention
GROUP BY cohort_month
ORDER BY cohort_month;


-- =====================================================
-- 4.  RFM SEGMENTATION (Recency, Frequency, Monetary)
-- =====================================================
-- Scores each customer 1–5 on three dimensions, then
-- combines into an RFM segment label.
-- Reference date: 2024-09-24 (day after last transaction).

WITH rfm_raw AS (
    SELECT
        customer_id,
        DATEDIFF('2024-09-24', MAX(purchase_date))     AS recency_days,
        COUNT(DISTINCT order_id)                        AS frequency,
        SUM(order_revenue)                              AS monetary
    FROM v_order_summary
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        ROUND(monetary, 2)                              AS monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC)      AS r_score,   -- 5 = most recent
        NTILE(5) OVER (ORDER BY frequency ASC)           AS f_score,   -- 5 = most frequent
        NTILE(5) OVER (ORDER BY monetary ASC)            AS m_score    -- 5 = highest spend
    FROM rfm_raw
)
SELECT
    customer_id,
    recency_days,
    frequency,
    FORMAT(monetary, 2)                                 AS monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score)                   AS rfm_code,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3
            THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2
            THEN 'Recent Customers'
        WHEN r_score >= 3 AND f_score >= 3
            THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3
            THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4
            THEN 'Can\'t Lose Them'
        WHEN r_score <= 2 AND f_score <= 2
            THEN 'Lost'
        ELSE 'Needs Attention'
    END                                                 AS rfm_segment
FROM rfm_scored
ORDER BY monetary DESC
LIMIT 50;


-- 4b.  RFM Segment Summary
-- Aggregates the RFM output into actionable segment counts.

WITH rfm_raw AS (
    SELECT
        customer_id,
        DATEDIFF('2024-09-24', MAX(purchase_date))     AS recency_days,
        COUNT(DISTINCT order_id)                        AS frequency,
        SUM(order_revenue)                              AS monetary
    FROM v_order_summary
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC)      AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)           AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)            AS m_score
    FROM rfm_raw
),
rfm_segmented AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 4 AND f_score >= 3              THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2              THEN 'Recent Customers'
            WHEN r_score >= 3 AND f_score >= 3              THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 3              THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Can\'t Lose Them'
            WHEN r_score <= 2 AND f_score <= 2              THEN 'Lost'
            ELSE 'Needs Attention'
        END AS rfm_segment
    FROM rfm_scored
)
SELECT
    rfm_segment,
    COUNT(*)                                            AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total,
    FORMAT(ROUND(AVG(monetary), 2), 2)                  AS avg_revenue,
    ROUND(AVG(frequency), 1)                            AS avg_orders,
    ROUND(AVG(recency_days), 0)                         AS avg_recency_days
FROM rfm_segmented
GROUP BY rfm_segment
ORDER BY AVG(monetary) DESC;


-- =====================================================
-- 5.  SEASONALITY DETECTION
-- =====================================================
-- Compares each month's revenue to the 12-month average
-- to identify peaks and troughs.

WITH monthly AS (
    SELECT
        DATE_FORMAT(purchase_date, '%Y-%m')     AS month,
        MONTHNAME(purchase_date)                AS month_name,
        MONTH(purchase_date)                    AS month_num,
        SUM(order_revenue)                      AS revenue,
        COUNT(*)                                AS orders
    FROM v_order_summary
    WHERE order_status = 'Completed'
    GROUP BY DATE_FORMAT(purchase_date, '%Y-%m'),
             MONTHNAME(purchase_date),
             MONTH(purchase_date)
)
SELECT
    month,
    month_name,
    FORMAT(revenue, 2)                                  AS revenue,
    orders,
    FORMAT(ROUND(AVG(revenue) OVER (), 2), 2)           AS avg_monthly_revenue,
    ROUND(
        (revenue - AVG(revenue) OVER ())
        / AVG(revenue) OVER () * 100, 1
    )                                                   AS pct_deviation_from_avg,
    CASE
        WHEN revenue > AVG(revenue) OVER () * 1.10 THEN 'PEAK'
        WHEN revenue < AVG(revenue) OVER () * 0.90 THEN 'TROUGH'
        ELSE 'NORMAL'
    END                                                 AS seasonality_flag
FROM monthly
ORDER BY month;


-- =====================================================
-- 6.  PRODUCT PERFORMANCE TREND OVER TIME
-- =====================================================
-- Tracks each product category's monthly revenue and
-- ranks them within each month using window functions.

WITH monthly_product AS (
    SELECT
        DATE_FORMAT(o.purchase_date, '%Y-%m')       AS month,
        pc.category_name                            AS product_category,
        SUM(oi.line_total)                          AS revenue,
        SUM(oi.quantity)                             AS units_sold,
        ROUND(AVG(oi.rating), 2)                    AS avg_rating
    FROM order_items oi
    JOIN orders o           ON oi.order_id    = o.order_id
    JOIN order_statuses os  ON o.status_id    = os.status_id
    JOIN products p         ON oi.product_id  = p.product_id
    JOIN product_categories pc ON p.category_id = pc.category_id
    WHERE os.status_name = 'Completed'
    GROUP BY DATE_FORMAT(o.purchase_date, '%Y-%m'), pc.category_name
)
SELECT
    month,
    product_category,
    FORMAT(revenue, 2)                              AS revenue,
    units_sold,
    avg_rating,
    RANK() OVER (
        PARTITION BY month
        ORDER BY revenue DESC
    )                                               AS rank_in_month,
    FORMAT(ROUND(
        revenue - LAG(revenue) OVER (
            PARTITION BY product_category
            ORDER BY month
        ), 2
    ), 2)                                           AS mom_revenue_change
FROM monthly_product
ORDER BY month, revenue DESC;


-- =====================================================
-- 7.  LOYALTY PROGRAM ENROLLMENT IMPACT
-- =====================================================
-- Compares customer spend BEFORE and AFTER loyalty enrollment
-- for customers who joined mid-dataset.

WITH enrolled_customers AS (
    SELECT
        customer_id,
        loyalty_start_date
    FROM customers
    WHERE current_loyalty = 'Yes'
      AND loyalty_start_date IS NOT NULL
),
spend_comparison AS (
    SELECT
        ec.customer_id,
        SUM(CASE WHEN o.purchase_date < ec.loyalty_start_date
            THEN vs.order_revenue ELSE 0 END)           AS pre_enrollment_spend,
        SUM(CASE WHEN o.purchase_date >= ec.loyalty_start_date
            THEN vs.order_revenue ELSE 0 END)           AS post_enrollment_spend,
        COUNT(DISTINCT CASE WHEN o.purchase_date < ec.loyalty_start_date
            THEN o.order_id END)                         AS pre_orders,
        COUNT(DISTINCT CASE WHEN o.purchase_date >= ec.loyalty_start_date
            THEN o.order_id END)                         AS post_orders
    FROM enrolled_customers ec
    JOIN orders o           ON ec.customer_id = o.customer_id
    JOIN v_order_summary vs ON o.order_id     = vs.order_id
    WHERE vs.order_status = 'Completed'
    GROUP BY ec.customer_id
    HAVING pre_orders > 0 AND post_orders > 0
)
SELECT
    COUNT(*)                                            AS customers_with_both,
    FORMAT(ROUND(AVG(pre_enrollment_spend), 2), 2)      AS avg_pre_spend,
    FORMAT(ROUND(AVG(post_enrollment_spend), 2), 2)     AS avg_post_spend,
    ROUND(
        (AVG(post_enrollment_spend) - AVG(pre_enrollment_spend))
        / NULLIF(AVG(pre_enrollment_spend), 0) * 100, 1
    )                                                   AS spend_change_pct,
    ROUND(AVG(pre_orders), 1)                           AS avg_pre_orders,
    ROUND(AVG(post_orders), 1)                          AS avg_post_orders;


-- =====================================================
-- 8.  CANCELLATION RISK PROFILING
-- =====================================================
-- Identifies which product + payment + shipping combos
-- have the highest cancellation rates.

SELECT
    pc.category_name                                    AS product_category,
    pm.payment_type                                     AS payment_method,
    sm.shipping_type,
    COUNT(*)                                            AS total_orders,
    SUM(CASE WHEN os.status_name = 'Cancelled'
        THEN 1 ELSE 0 END)                             AS cancelled,
    ROUND(
        SUM(CASE WHEN os.status_name = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                                   AS cancellation_rate_pct,
    FORMAT(SUM(CASE WHEN os.status_name = 'Cancelled'
        THEN oi.line_total ELSE 0 END), 2)              AS lost_revenue
FROM order_items oi
JOIN orders o           ON oi.order_id    = o.order_id
JOIN order_statuses os  ON o.status_id    = os.status_id
JOIN products p         ON oi.product_id  = p.product_id
JOIN product_categories pc ON p.category_id = pc.category_id
JOIN payment_methods pm ON o.payment_id   = pm.payment_id
JOIN shipping_methods sm ON o.shipping_id = sm.shipping_id
GROUP BY pc.category_name, pm.payment_type, sm.shipping_type
HAVING COUNT(*) >= 20
ORDER BY cancellation_rate_pct DESC
LIMIT 20;


-- =====================================================
-- 9.  ADD-ON CROSS-SELL EFFECTIVENESS
-- =====================================================
-- Measures which add-on types attach to which product
-- categories, and their revenue contribution.

SELECT
    pc.category_name                                    AS product_category,
    at.addon_name                                       AS addon_type,
    COUNT(oa.addon_id)                                  AS times_attached,
    FORMAT(SUM(oa.addon_price), 2)                      AS addon_revenue,
    FORMAT(ROUND(AVG(oa.addon_price), 2), 2)            AS avg_addon_price,
    ROUND(
        COUNT(oa.addon_id) * 100.0
        / SUM(COUNT(oa.addon_id)) OVER (PARTITION BY pc.category_name), 1
    )                                                   AS pct_of_category_addons
FROM order_addons oa
JOIN addon_types at     ON oa.addon_type_id   = at.addon_type_id
JOIN order_items oi     ON oa.order_item_id   = oi.order_item_id
JOIN products p         ON oi.product_id      = p.product_id
JOIN product_categories pc ON p.category_id   = pc.category_id
JOIN orders o           ON oi.order_id        = o.order_id
JOIN order_statuses os  ON o.status_id        = os.status_id
WHERE os.status_name = 'Completed'
GROUP BY pc.category_name, at.addon_name
ORDER BY pc.category_name, SUM(oa.addon_price) DESC;


-- =====================================================
-- 10. MONTHLY REVENUE MOVING AVERAGE + MoM GROWTH
-- =====================================================
-- Calculates 3-month rolling average and month-over-month
-- growth rate using window functions.

WITH monthly AS (
    SELECT
        DATE_FORMAT(purchase_date, '%Y-%m')     AS month,
        SUM(order_revenue)                      AS revenue,
        COUNT(*)                                AS orders
    FROM v_order_summary
    WHERE order_status = 'Completed'
    GROUP BY DATE_FORMAT(purchase_date, '%Y-%m')
)
SELECT
    month,
    FORMAT(revenue, 2)                                  AS revenue,
    orders,
    FORMAT(ROUND(
        AVG(revenue) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ), 2)                                               AS rolling_3mo_avg,
    FORMAT(ROUND(
        LAG(revenue) OVER (ORDER BY month), 2
    ), 2)                                               AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 1
    )                                                   AS mom_growth_pct
FROM monthly
ORDER BY month;


-- =====================================================
-- END OF ADVANCED ANALYSIS
-- =====================================================

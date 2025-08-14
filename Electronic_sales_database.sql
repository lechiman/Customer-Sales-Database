-- Electronic Sales Dataset Advanced Analysis Script
-- Dataset: Electronic Sales Sep 2023 - Sep 2024


DROP DATABASE IF EXISTS electronic_sales_db;
CREATE DATABASE electronic_sales_db;
USE electronic_sales_db;

-- Main table structure for electronic sales dataset
CREATE TABLE sales (
    customer_id INT NOT NULL,
    age INT,
    gender ENUM('Male', 'Female') NOT NULL,
    loyalty_member ENUM('Yes', 'No') NOT NULL DEFAULT 'No',
    product_type VARCHAR(50) NOT NULL,
    sku VARCHAR(20) NOT NULL,
    rating INT, -- Rating scale: 1-5
    order_status ENUM('Completed', 'Cancelled') NOT NULL,
    payment_method ENUM('Credit Card', 'Paypal', 'Cash', 'Debit Card') NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    purchase_date DATE NOT NULL,
    shipping_type ENUM('Standard', 'Express', 'Overnight') NOT NULL,
    addons_purchased TEXT,
    addon_total DECIMAL(10,2) DEFAULT 0,
    -- Primary key and indexes
    PRIMARY KEY (customer_id, purchase_date, sku),
    INDEX idx_purchase_date (purchase_date),
    INDEX idx_customer_id (customer_id),
    INDEX idx_product_type (product_type),
    INDEX idx_order_status (order_status),
    INDEX idx_payment_method (payment_method),
    INDEX idx_loyalty_member (loyalty_member),
    INDEX idx_total_price (total_price),
    INDEX idx_rating (rating),
    INDEX idx_age (age),
    INDEX idx_gender (gender),
    INDEX idx_shipping_type (shipping_type)
);

-- Data import validation
SELECT 
    'Data Import Validation' as report_section,
    'Total Orders' as metric,
    FORMAT(COUNT(*), 0) as value
FROM sales
UNION ALL
SELECT 
    'Data Quality',
    'Completed Orders',
    CONCAT(FORMAT(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END), 0), ' (', 
           ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1), '%)')
FROM sales
UNION ALL
SELECT 
    'Data Quality',
    'Loyalty Members', 
    CONCAT(FORMAT(COUNT(CASE WHEN loyalty_member = 'Yes' THEN 1 END), 0), ' (', 
           ROUND(COUNT(CASE WHEN loyalty_member = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1), '%)')
FROM sales
UNION ALL
SELECT 
    'Data Quality',
    'Orders with Add-ons',
    CONCAT(FORMAT(COUNT(CASE WHEN addon_total > 0 THEN 1 END), 0), ' (', 
           ROUND(COUNT(CASE WHEN addon_total > 0 THEN 1 END) * 100.0 / COUNT(*), 1), '%)')
FROM sales;

-- ANALYTICAL QUESTION 1: Customer Demographics Analysis

-- Customer Age Group Performance
SELECT 
    'Q1: Customer Demographics Analysis' as analysis,
    CASE 
        WHEN age < 25 THEN 'Gen Z (18-24)'
        WHEN age < 35 THEN 'Millennials (25-34)'
        WHEN age < 45 THEN 'Gen X (35-44)'
        WHEN age < 55 THEN 'Baby Boomers (45-54)'
        WHEN age < 65 THEN 'Seniors (55-64)'
        ELSE 'Elderly (65+)'
    END as age_group,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(AVG(total_price), 2) as avg_order_value,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(rating), 2) as avg_rating,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate,
    ROUND(COUNT(CASE WHEN loyalty_member = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1) as loyalty_rate
FROM sales
GROUP BY age_group
ORDER BY total_revenue DESC;

-- Gender-based Purchase Analysis
SELECT 
    'Q1: Gender Purchase Patterns' as analysis,
    gender,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(AVG(total_price), 2) as avg_order_value,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(quantity), 2) as avg_quantity,
    ROUND(AVG(rating), 2) as avg_rating
FROM sales
GROUP BY gender
ORDER BY total_revenue DESC;

-- ANALYTICAL QUESTION 2: Product Performance Analysis

-- Product Type Revenue Analysis
SELECT 
    'Q2: Product Performance Analysis' as analysis,
    product_type,
    COUNT(*) as total_orders,
    ROUND(AVG(total_price), 2) as avg_order_value,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(rating), 2) as avg_rating,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate,
    ROUND(AVG(unit_price), 2) as avg_unit_price,
    SUM(quantity) as total_units_sold
FROM sales
GROUP BY product_type
ORDER BY SUM(total_price) DESC;

-- SKU Performance Analysis
SELECT 
    'Q2: Top Performing SKUs' as analysis,
    sku,
    product_type,
    COUNT(*) as order_count,
    SUM(quantity) as units_sold,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(rating), 2) as avg_rating,
    ROUND(AVG(unit_price), 2) as avg_unit_price,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate
FROM sales
GROUP BY sku, product_type
ORDER BY SUM(total_price) DESC
LIMIT 10;

-- ANALYTICAL QUESTION 3: Sales Trends Over Time

-- Monthly Sales Trends
SELECT 
    'Q3: Monthly Sales Trends' as analysis,
    MONTHNAME(purchase_date) as month_name,
    MONTH(purchase_date) as month_number,
    COUNT(*) as total_orders,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(total_price), 2) as avg_order_value,
    COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) as completed_orders,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate
FROM sales
GROUP BY MONTH(purchase_date), MONTHNAME(purchase_date)
ORDER BY month_number;

-- Seasonal Analysis
SELECT 
    'Q3: Seasonal Analysis' as analysis,
    CASE 
        WHEN MONTH(purchase_date) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(purchase_date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(purchase_date) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END as season,
    COUNT(*) as total_orders,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(total_price), 2) as avg_order_value,
    ROUND(AVG(rating), 2) as avg_rating
FROM sales
GROUP BY season
ORDER BY SUM(total_price) DESC;

-- ANALYTICAL QUESTION 4: Customer Loyalty Analysis

-- Loyalty Member vs Non-Member Analysis
SELECT 
    'Q4: Loyalty Member Analysis' as analysis,
    loyalty_member,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(AVG(total_price), 2) as avg_order_value,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(rating), 2) as avg_rating,
    ROUND(AVG(addon_total), 2) as avg_addon_spend,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate
FROM sales
GROUP BY loyalty_member
ORDER BY total_revenue DESC;

-- Customer Purchase Frequency Analysis
SELECT 
    'Q4: Customer Purchase Frequency' as analysis,
    purchase_frequency,
    COUNT(*) as customer_count,
    ROUND(AVG(avg_order_value), 2) as avg_order_value,
    FORMAT(SUM(total_spent), 2) as total_revenue_from_group
FROM (
    SELECT 
        customer_id,
        COUNT(*) as order_count,
        ROUND(AVG(total_price), 2) as avg_order_value,
        SUM(total_price) as total_spent,
        CASE 
            WHEN COUNT(*) = 1 THEN 'One-time Buyers'
            WHEN COUNT(*) <= 3 THEN 'Occasional Buyers (2-3)'
            WHEN COUNT(*) <= 6 THEN 'Regular Buyers (4-6)'
            ELSE 'Frequent Buyers (7+)'
        END as purchase_frequency
    FROM sales
    WHERE order_status = 'Completed'
    GROUP BY customer_id
) customer_segments
GROUP BY purchase_frequency
ORDER BY customer_count DESC;

-- ANALYTICAL QUESTION 5: Payment Method Preferences


-- Payment Method Analysis
SELECT 
    'Q5: Payment Method Analysis' as analysis,
    payment_method,
    COUNT(*) as total_orders,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(total_price), 2) as avg_order_value,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate,
    ROUND(COUNT(CASE WHEN loyalty_member = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1) as loyalty_member_rate
FROM sales
GROUP BY payment_method
ORDER BY SUM(total_price) DESC;

-- Payment Method by Age Group
SELECT 
    'Q5: Payment Method by Demographics' as analysis,
    CASE 
        WHEN age < 35 THEN 'Young (18-34)'
        WHEN age < 55 THEN 'Middle-aged (35-54)'
        ELSE 'Older (55+)'
    END as age_segment,
    payment_method,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY 
        CASE 
            WHEN age < 35 THEN 'Young (18-34)'
            WHEN age < 55 THEN 'Middle-aged (35-54)'
            ELSE 'Older (55+)'
        END), 1) as percentage_within_age_group
FROM sales
GROUP BY age_segment, payment_method
ORDER BY age_segment, order_count DESC;


-- ANALYTICAL QUESTION 6: Shipping Preferences Analysis


-- Shipping Type Performance
SELECT 
    'Q6: Shipping Type Analysis' as analysis,
    shipping_type,
    COUNT(*) as total_orders,
    FORMAT(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(total_price), 2) as avg_order_value,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate,
    ROUND(AVG(rating), 2) as avg_rating
FROM sales
GROUP BY shipping_type
ORDER BY SUM(total_price) DESC;

-- Shipping Preference by Product Type
SELECT 
    'Q6: Shipping Preference by Product' as analysis,
    product_type,
    shipping_type,
    COUNT(*) as order_count,
    ROUND(AVG(total_price), 2) as avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY product_type), 1) as percentage_within_product
FROM sales
GROUP BY product_type, shipping_type
ORDER BY product_type, order_count DESC;


-- ANALYTICAL QUESTION 7: Add-on Sales Effectiveness


-- Create helper function to extract primary add-on
DROP FUNCTION IF EXISTS get_primary_addon;
DELIMITER $$
CREATE FUNCTION get_primary_addon(addon_string TEXT) 
RETURNS VARCHAR(100)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE first_addon VARCHAR(100);
    IF addon_string IS NULL OR addon_string = '' THEN
        RETURN 'No Add-on';
    END IF;
    SET first_addon = TRIM(SUBSTRING_INDEX(addon_string, ',', 1));
    RETURN COALESCE(first_addon, 'No Add-on');
END$$
DELIMITER ;

-- Add-on Sales Analysis
SELECT 
    'Q7: Add-on Sales Effectiveness' as analysis,
    CASE 
        WHEN addon_total = 0 THEN 'No Add-ons'
        WHEN addon_total <= 25 THEN 'Low Add-on (<$25)'
        WHEN addon_total <= 50 THEN 'Medium Add-on ($25-$50)'
        WHEN addon_total <= 75 THEN 'High Add-on ($50-$75)'
        ELSE 'Premium Add-on (>$75)'
    END as addon_category,
    COUNT(*) as order_count,
    FORMAT(SUM(total_price), 2) as total_revenue,
    FORMAT(SUM(addon_total), 2) as total_addon_revenue,
    ROUND(AVG(total_price), 2) as avg_order_value,
    ROUND(AVG(addon_total), 2) as avg_addon_value,
    ROUND(AVG(rating), 2) as avg_rating
FROM sales
GROUP BY addon_category
ORDER BY avg_order_value DESC;

-- Add-on Type Performance
SELECT 
    'Q7: Add-on Type Performance' as analysis,
    get_primary_addon(addons_purchased) as primary_addon,
    COUNT(*) as order_count,
    FORMAT(SUM(addon_total), 2) as total_addon_revenue,
    ROUND(AVG(addon_total), 2) as avg_addon_value,
    ROUND(AVG(total_price), 2) as avg_order_value,
    ROUND(AVG(rating), 2) as avg_rating
FROM sales
WHERE addon_total > 0
GROUP BY primary_addon
ORDER BY SUM(addon_total) DESC;


-- ANALYTICAL QUESTION 8: Order Completion Analysis


-- Order Cancellation Analysis
SELECT 
    'Q8: Order Completion Analysis' as analysis,
    product_type,
    COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) as completed_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) as cancelled_orders,
    COUNT(*) as total_orders,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate,
    FORMAT(SUM(CASE WHEN order_status = 'Completed' THEN total_price ELSE 0 END), 2) as completed_revenue,
    FORMAT(SUM(CASE WHEN order_status = 'Cancelled' THEN total_price ELSE 0 END), 2) as lost_revenue
FROM sales
GROUP BY product_type
ORDER BY completion_rate DESC;

-- Cancellation Factors Analysis
SELECT 
    'Q8: Cancellation Risk Factors' as analysis,
    CASE 
        WHEN total_price < 500 THEN 'Low Value (<$500)'
        WHEN total_price < 1500 THEN 'Medium Value ($500-$1500)'
        WHEN total_price < 3000 THEN 'High Value ($1500-$3000)'
        ELSE 'Premium Value (>$3000)'
    END as order_value_category,
    payment_method,
    shipping_type,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) as cancelled_orders,
    ROUND(COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*), 1) as cancellation_rate
FROM sales
GROUP BY order_value_category, payment_method, shipping_type
HAVING COUNT(*) >= 10
ORDER BY cancellation_rate DESC
LIMIT 20;
-- ANALYTICAL QUESTION 9: Rating and Satisfaction Analysis


-- Customer Satisfaction by Product
SELECT 
    'Q9: Customer Satisfaction Analysis' as analysis,
    product_type,
    ROUND(AVG(rating), 2) as avg_rating,
    COUNT(CASE WHEN rating >= 4 THEN 1 END) as satisfied_customers,
    COUNT(CASE WHEN rating <= 2 THEN 1 END) as unsatisfied_customers,
    COUNT(*) as total_ratings,
    ROUND(COUNT(CASE WHEN rating >= 4 THEN 1 END) * 100.0 / COUNT(*), 1) as satisfaction_rate,
    FORMAT(AVG(total_price), 2) as avg_order_value_for_product
FROM sales
WHERE rating IS NOT NULL
GROUP BY product_type
ORDER BY avg_rating DESC;

-- Rating Impact on Repeat Purchases
SELECT 
    'Q9: Rating Impact on Customer Behavior' as analysis,
    rating as customer_rating,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(AVG(order_count), 2) as avg_orders_per_customer,
    ROUND(AVG(total_spent), 2) as avg_customer_value,
    ROUND(AVG(CASE WHEN loyalty_member = 'Yes' THEN 1 ELSE 0 END) * 100, 1) as loyalty_rate
FROM (
    SELECT 
        customer_id,
        rating,
        COUNT(*) as order_count,
        SUM(total_price) as total_spent,
        loyalty_member
    FROM sales
    WHERE rating IS NOT NULL AND order_status = 'Completed'
    GROUP BY customer_id, rating, loyalty_member
) customer_rating_behavior
GROUP BY rating
ORDER BY rating DESC;


-- ANALYTICAL QUESTION 10: High-Value Customer Analysis

-- Customer Value Segmentation
SELECT 
    'Q10: Customer Value Segmentation' as analysis,
    customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_customer_value,
    ROUND(AVG(order_count), 2) as avg_orders_per_customer,
    ROUND(AVG(avg_order_value), 2) as avg_order_value,
    FORMAT(SUM(total_spent), 2) as segment_total_revenue,
    ROUND(SUM(total_spent) * 100.0 / (SELECT SUM(total_price) FROM sales WHERE order_status = 'Completed'), 1) as revenue_percentage
FROM (
    SELECT 
        customer_id,
        COUNT(*) as order_count,
        SUM(total_price) as total_spent,
        ROUND(AVG(total_price), 2) as avg_order_value,
        CASE 
            WHEN SUM(total_price) >= 10000 THEN 'VIP ($10K+)'
            WHEN SUM(total_price) >= 5000 THEN 'High Value ($5K-$10K)'
            WHEN SUM(total_price) >= 2000 THEN 'Medium Value ($2K-$5K)'
            WHEN SUM(total_price) >= 500 THEN 'Regular ($500-$2K)'
            ELSE 'Low Value (<$500)'
        END as customer_segment
    FROM sales
    WHERE order_status = 'Completed'
    GROUP BY customer_id
) customer_segments
GROUP BY customer_segment
ORDER BY avg_customer_value DESC;

-- ANALYTICAL QUESTION 11: Product Bundling Opportunities


-- Cross-selling Analysis
SELECT 
    'Q11: Product Cross-selling Analysis' as analysis,
    p1.product_type as primary_product,
    p2.product_type as secondary_product,
    COUNT(*) as co_purchase_count,
    COUNT(DISTINCT p1.customer_id) as unique_customers,
    ROUND(AVG(p1.total_price + p2.total_price), 2) as avg_combined_value
FROM sales p1
JOIN sales p2 ON p1.customer_id = p2.customer_id 
    AND p1.product_type != p2.product_type
    AND p1.purchase_date = p2.purchase_date
WHERE p1.order_status = 'Completed' AND p2.order_status = 'Completed'
GROUP BY p1.product_type, p2.product_type
HAVING COUNT(*) >= 5
ORDER BY co_purchase_count DESC
LIMIT 15;


-- ADVANCED VIEWS FOR FURTHER ANALYSIS


-- Create comprehensive customer analysis view
DROP VIEW IF EXISTS customer_analytics;
CREATE VIEW customer_analytics AS
SELECT 
    customer_id,
    age,
    gender,
    loyalty_member,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) as completed_orders,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate,
    SUM(total_price) as total_spent,
    ROUND(AVG(total_price), 2) as avg_order_value,
    SUM(addon_total) as total_addon_spend,
    ROUND(AVG(rating), 2) as avg_rating,
    MIN(purchase_date) as first_purchase,
    MAX(purchase_date) as last_purchase,
    DATEDIFF(MAX(purchase_date), MIN(purchase_date)) as customer_lifespan_days
FROM sales
GROUP BY customer_id, age, gender, loyalty_member;

-- Create product performance view
DROP VIEW IF EXISTS product_performance;
CREATE VIEW product_performance AS
SELECT 
    product_type,
    sku,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) as completed_orders,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) as completion_rate,
    SUM(quantity) as units_sold,
    SUM(total_price) as total_revenue,
    ROUND(AVG(unit_price), 2) as avg_unit_price,
    ROUND(AVG(rating), 2) as avg_rating,
    ROUND(AVG(addon_total), 2) as avg_addon_revenue
FROM sales
GROUP BY product_type, sku;


-- EXECUTIVE SUMMARY QUERY


-- Key Business Insights Summary
SELECT 
    'EXECUTIVE SUMMARY' as section,
    'Total Orders' as metric,
    FORMAT(COUNT(*), 0) as value
FROM sales
UNION ALL
SELECT 
    'Revenue Performance',
    'Total Revenue',
    FORMAT(SUM(total_price), 2)
FROM sales
WHERE order_status = 'Completed'
UNION ALL
SELECT 
    'Customer Base',
    'Unique Customers',
    FORMAT(COUNT(DISTINCT customer_id), 0)
FROM sales
UNION ALL
SELECT 
    'Order Performance',
    'Completion Rate',
    CONCAT(ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1), '%')
FROM sales
UNION ALL
SELECT 
    'Customer Loyalty',
    'Loyalty Member Rate',
    CONCAT(ROUND(COUNT(CASE WHEN loyalty_member = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1), '%')
FROM sales
UNION ALL
SELECT 
    'Product Performance',
    'Average Order Value',
    CONCAT('$', FORMAT(ROUND(AVG(total_price), 2), 2))
FROM sales
WHERE order_status = 'Completed'
UNION ALL
SELECT 
    'Add-on Success',
    'Add-on Attachment Rate',
    CONCAT(ROUND(COUNT(CASE WHEN addon_total > 0 THEN 1 END) * 100.0 / COUNT(*), 1), '%')
FROM sales
UNION ALL
SELECT 
    'Customer Satisfaction',
    'Average Rating',
    CONCAT(ROUND(AVG(rating), 2), '/5')
FROM sales
WHERE rating IS NOT NULL;

-- Performance optimization indexes
CREATE INDEX idx_customer_analysis ON sales(customer_id, order_status, total_price);
CREATE INDEX idx_product_analysis ON sales(product_type, sku, rating);
CREATE INDEX idx_date_revenue ON sales(purchase_date, total_price, order_status);
CREATE INDEX idx_loyalty_analysis ON sales(loyalty_member, total_price, addon_total);

-- End of Script
SELECT 'Electronic Sales Analysis Complete!' as status,
       CONCAT('Dataset covers ', 
              DATE_FORMAT(MIN(purchase_date), '%M %Y'), ' to ', 
              DATE_FORMAT(MAX(purchase_date), '%M %Y')) as date_range,
       FORMAT(COUNT(*), 0) as total_records_analyzed
FROM sales;
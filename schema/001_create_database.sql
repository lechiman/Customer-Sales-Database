-- =====================================================
-- Electronic Sales Database — Normalized Schema (3NF)
-- Version: 2.0
-- Dataset: Electronic Sales Sep 2023 – Sep 2024
-- =====================================================
-- This schema replaces the original flat "sales" table
-- with a properly normalized relational design.
-- =====================================================

DROP DATABASE IF EXISTS electronic_sales_db;
CREATE DATABASE electronic_sales_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE electronic_sales_db;

-- =====================================================
-- LOOKUP / REFERENCE TABLES
-- =====================================================

-- Shipping methods lookup
CREATE TABLE shipping_methods (
    shipping_id     TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    shipping_type   VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO shipping_methods (shipping_type) VALUES
    ('Standard'),
    ('Express'),
    ('Expedited'),
    ('Overnight'),
    ('Same Day');

-- Payment methods lookup
CREATE TABLE payment_methods (
    payment_id      TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_type    VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO payment_methods (payment_type) VALUES
    ('Credit Card'),
    ('Debit Card'),
    ('PayPal'),
    ('Cash'),
    ('Bank Transfer');

-- Order status lookup
CREATE TABLE order_statuses (
    status_id       TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    status_name     VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO order_statuses (status_name) VALUES
    ('Completed'),
    ('Cancelled');

-- Product categories
CREATE TABLE product_categories (
    category_id     TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name   VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO product_categories (category_name) VALUES
    ('Smartphone'),
    ('Laptop'),
    ('Tablet'),
    ('Smartwatch'),
    ('Headphones');

-- Add-on product types
CREATE TABLE addon_types (
    addon_type_id   TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    addon_name      VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO addon_types (addon_name) VALUES
    ('Accessory'),
    ('Impulse Item'),
    ('Extended Warranty');

-- =====================================================
-- CORE ENTITY TABLES
-- =====================================================

-- Customers
-- One row per unique customer. Demographics stored once.
CREATE TABLE customers (
    customer_id         INT UNSIGNED NOT NULL PRIMARY KEY,
    age                 TINYINT UNSIGNED,
    gender              ENUM('Male', 'Female') DEFAULT NULL,
    current_loyalty     ENUM('Yes', 'No') NOT NULL DEFAULT 'No',
    loyalty_start_date  DATE DEFAULT NULL COMMENT 'Earliest transaction where loyalty = Yes',
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CHECK (age BETWEEN 18 AND 120)
) ENGINE=InnoDB;

CREATE INDEX idx_customers_loyalty ON customers (current_loyalty);
CREATE INDEX idx_customers_gender ON customers (gender);
CREATE INDEX idx_customers_age ON customers (age);

-- Products
-- One row per unique product variant (SKU + category + price).
-- NOTE: The raw data contains SKUs shared across product types
-- (e.g., SKU1004 appears as both Smartphone and Laptop).
-- In the normalized schema, each combination gets its own product_id.
CREATE TABLE products (
    product_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku             VARCHAR(20) NOT NULL,
    category_id     TINYINT UNSIGNED NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES product_categories (category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    UNIQUE KEY uq_product_variant (sku, category_id, unit_price),

    CHECK (unit_price > 0)
) ENGINE=InnoDB;

CREATE INDEX idx_products_sku ON products (sku);
CREATE INDEX idx_products_category ON products (category_id);

-- =====================================================
-- TRANSACTIONAL TABLES
-- =====================================================

-- Orders
-- One row per customer transaction.
CREATE TABLE orders (
    order_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT UNSIGNED NOT NULL,
    purchase_date   DATE NOT NULL,
    status_id       TINYINT UNSIGNED NOT NULL,
    payment_id      TINYINT UNSIGNED NOT NULL,
    shipping_id     TINYINT UNSIGNED NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_status
        FOREIGN KEY (status_id) REFERENCES order_statuses (status_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_payment
        FOREIGN KEY (payment_id) REFERENCES payment_methods (payment_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_shipping
        FOREIGN KEY (shipping_id) REFERENCES shipping_methods (shipping_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_date ON orders (purchase_date);
CREATE INDEX idx_orders_status ON orders (status_id);
CREATE INDEX idx_orders_date_status ON orders (purchase_date, status_id);

-- Order items
-- One row per product line within an order.
CREATE TABLE order_items (
    order_item_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id        INT UNSIGNED NOT NULL,
    product_id      INT UNSIGNED NOT NULL,
    quantity        INT UNSIGNED NOT NULL DEFAULT 1,
    unit_price      DECIMAL(10,2) NOT NULL COMMENT 'Price at time of purchase (snapshot)',
    line_total      DECIMAL(10,2) GENERATED ALWAYS AS (unit_price * quantity) STORED,
    rating          TINYINT UNSIGNED DEFAULT NULL,

    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CHECK (quantity > 0),
    CHECK (unit_price >= 0),
    CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE INDEX idx_items_order ON order_items (order_id);
CREATE INDEX idx_items_product ON order_items (product_id);

-- Order add-ons
-- One row per add-on attached to an order item.
-- Replaces the comma-separated addons_purchased text field.
CREATE TABLE order_addons (
    addon_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_item_id   INT UNSIGNED NOT NULL,
    addon_type_id   TINYINT UNSIGNED NOT NULL,
    addon_price     DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT fk_addons_item
        FOREIGN KEY (order_item_id) REFERENCES order_items (order_item_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_addons_type
        FOREIGN KEY (addon_type_id) REFERENCES addon_types (addon_type_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CHECK (addon_price >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_addons_item ON order_addons (order_item_id);
CREATE INDEX idx_addons_type ON order_addons (addon_type_id);

-- Loyalty program history
-- Tracks when a customer's loyalty status changed.
-- The raw data shows 2,270 customers with both Yes and No across transactions.
CREATE TABLE loyalty_history (
    history_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT UNSIGNED NOT NULL,
    status          ENUM('Yes', 'No') NOT NULL,
    effective_date  DATE NOT NULL,
    recorded_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_loyalty_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_loyalty_customer ON loyalty_history (customer_id, effective_date);

-- =====================================================
-- ANALYTICAL VIEWS
-- =====================================================

-- Revenue per order (replaces manual total_price + addon_total math)
CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.order_id,
    o.customer_id,
    o.purchase_date,
    os.status_name                                  AS order_status,
    pm.payment_type                                 AS payment_method,
    sm.shipping_type                                AS shipping_type,
    COALESCE(items.product_total, 0)                AS product_total,
    COALESCE(items.addon_total, 0)                  AS addon_total,
    COALESCE(items.product_total, 0)
        + COALESCE(items.addon_total, 0)            AS order_revenue,
    items.item_count
FROM orders o
JOIN order_statuses os ON o.status_id = os.status_id
JOIN payment_methods pm ON o.payment_id = pm.payment_id
JOIN shipping_methods sm ON o.shipping_id = sm.shipping_id
LEFT JOIN (
    SELECT
        oi.order_id,
        SUM(oi.line_total)                          AS product_total,
        COALESCE(SUM(oa_agg.addon_sum), 0)          AS addon_total,
        COUNT(oi.order_item_id)                      AS item_count
    FROM order_items oi
    LEFT JOIN (
        SELECT order_item_id, SUM(addon_price) AS addon_sum
        FROM order_addons
        GROUP BY order_item_id
    ) oa_agg ON oi.order_item_id = oa_agg.order_item_id
    GROUP BY oi.order_id
) items ON o.order_id = items.order_id;

-- Customer-level analytics
CREATE OR REPLACE VIEW v_customer_analytics AS
SELECT
    c.customer_id,
    c.age,
    c.gender,
    c.current_loyalty,
    c.loyalty_start_date,
    COUNT(DISTINCT o.order_id)                                                      AS total_orders,
    COUNT(DISTINCT CASE WHEN os.status_name = 'Completed' THEN o.order_id END)      AS completed_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN os.status_name = 'Completed' THEN o.order_id END)
        * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 1
    )                                                                                AS completion_rate,
    ROUND(COALESCE(SUM(vs.order_revenue), 0), 2)                                    AS total_spent,
    ROUND(AVG(vs.order_revenue), 2)                                                  AS avg_order_value,
    MIN(o.purchase_date)                                                             AS first_purchase,
    MAX(o.purchase_date)                                                             AS last_purchase,
    DATEDIFF(MAX(o.purchase_date), MIN(o.purchase_date))                             AS customer_lifespan_days
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_statuses os ON o.status_id = os.status_id
LEFT JOIN v_order_summary vs ON o.order_id = vs.order_id
GROUP BY c.customer_id, c.age, c.gender, c.current_loyalty, c.loyalty_start_date;

-- Product performance
CREATE OR REPLACE VIEW v_product_performance AS
SELECT
    pc.category_name                                AS product_type,
    p.sku,
    COUNT(oi.order_item_id)                         AS total_orders,
    SUM(CASE WHEN os.status_name = 'Completed' THEN 1 ELSE 0 END) AS completed_orders,
    ROUND(
        SUM(CASE WHEN os.status_name = 'Completed' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(oi.order_item_id), 0), 1
    )                                               AS completion_rate,
    SUM(oi.quantity)                                 AS units_sold,
    ROUND(SUM(oi.line_total), 2)                    AS total_revenue,
    ROUND(AVG(oi.unit_price), 2)                    AS avg_unit_price,
    ROUND(AVG(oi.rating), 2)                        AS avg_rating
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_categories pc ON p.category_id = pc.category_id
JOIN orders o ON oi.order_id = o.order_id
JOIN order_statuses os ON o.status_id = os.status_id
GROUP BY pc.category_name, p.sku;

-- =====================================================
-- END OF SCHEMA
-- =====================================================
SELECT 'Schema created successfully. Ready for data import.' AS status;

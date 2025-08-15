# 📊 Electronic Sales Data Analysis Project

A comprehensive SQL-based business intelligence solution for analyzing electronic sales data from September 2023 to September 2024. This project provides deep insights into customer behavior, product performance, sales trends, and business metrics through advanced SQL analytics.

## 🎯 Project Overview

This project transforms raw electronic sales data into actionable business insights using MySQL. It features a complete database schema, automated analysis scripts, and 11 key analytical frameworks covering everything from customer demographics to product bundling opportunities.

## 📋 Table of Contents

- [Features](#features)
- [Database Schema](#database-schema)
- [Getting Started](#getting-started)
- [Data Import](#data-import)
- [Analysis Framework](#analysis-framework)
- [Key Insights](#key-insights)
- [Usage Examples](#usage-examples)
- [Sample Output](#sample-output)
- [Performance Optimization](#performance-optimization)

## ✨ Features

- **Comprehensive Database Design**: Optimized schema with proper indexing for fast queries
- **11 Analytical Frameworks**: Pre-built analyses covering all major business aspects
- **Customer Segmentation**: Advanced customer value and behavior analysis
- **Product Performance Tracking**: SKU-level performance metrics and trends
- **Seasonal Analysis**: Time-based sales patterns and seasonal insights
- **Loyalty Program Analytics**: Member vs. non-member performance comparison
- **Cross-selling Opportunities**: Product bundling and recommendation insights
- **Executive Dashboard**: High-level KPI summary for leadership
- **Data Quality Validation**: Built-in data validation and quality checks

## 🗄️ Database Schema

### Main Sales Table
The core `sales` table includes:
- **Customer Information**: ID, age, gender, loyalty status
- **Product Details**: Type, SKU, rating, unit price
- **Order Information**: Status, payment method, shipping type
- **Financial Data**: Total price, quantity, add-on purchases
- **Temporal Data**: Purchase dates for trend analysis

### Key Relationships
- Primary Key: `(customer_id, purchase_date, sku)`
- 10 Strategic Indexes for query optimization
- ENUM constraints for data integrity

## 🚀 Getting Started

### Prerequisites
- MySQL 5.7+ or MySQL 8.0+
- MySQL Workbench (recommended)
- Administrative privileges for database creation

### Installation

1. **Clone or Download** this repository
```bash
git clone [your-repository-url]
cd electronic-sales-data
```

2. **Create Database**
```sql
mysql -u root -p < Electronic_Sales_Database.sql
```

3. **Verify Installation**
```sql
USE electronic_sales_db;
SHOW TABLES;
```

## 📥 Data Import

### Method 1: MySQL Workbench (Recommended)
1. Right-click on the `sales` table
2. Select "Table Data Import Wizard"
3. Choose `Electronic_sales_Sep2023-Sep2024.csv`
4. Map columns appropriately
5. Execute import

### Method 2: Command Line
```sql
LOAD DATA INFILE '/path/to/Electronic_sales_Sep2023-Sep2024.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

## 📈 Analysis Framework

### 1. Customer Demographics Analysis
- Age group performance and behavior
- Gender-based purchasing patterns
- Generational spending analysis

### 2. Product Performance Analysis
- Product type revenue breakdown
- Top-performing SKU identification
- Unit economics analysis

### 3. Sales Trends Over Time
- Monthly and seasonal patterns
- Year-over-year comparisons
- Trend identification

### 4. Customer Loyalty Analysis
- Loyalty member vs. non-member metrics
- Purchase frequency segmentation
- Customer lifetime value

### 5. Payment Method Preferences
- Payment method performance
- Demographics-based preferences
- Completion rates by payment type

### 6. Shipping Preferences Analysis
- Shipping type popularity
- Product-specific shipping patterns
- Cost vs. speed preferences

### 7. Add-on Sales Effectiveness
- Add-on attachment rates
- Revenue impact analysis
- Cross-selling performance

### 8. Order Completion Analysis
- Cancellation rate analysis
- Risk factor identification
- Revenue impact assessment

### 9. Rating and Satisfaction Analysis
- Product satisfaction metrics
- Rating impact on repeat purchases
- Quality correlation analysis

### 10. High-Value Customer Analysis
- Customer value segmentation
- VIP customer identification
- Revenue concentration analysis

### 11. Product Bundling Opportunities
- Cross-selling patterns
- Product affinity analysis
- Bundle recommendation engine

## 🔍 Key Insights

The analysis framework provides answers to critical business questions:

- **Who are your most valuable customers?**
- **Which products drive the highest revenue?**
- **What are the seasonal sales patterns?**
- **How effective is your loyalty program?**
- **Which payment methods perform best?**
- **What drives order cancellations?**
- **How satisfied are your customers?**
- **What products sell well together?**

## 💡 Usage Examples

### Quick Start Analysis
```sql
-- Get executive summary
SELECT * FROM (
    -- Executive summary query here
) ORDER BY section;
```

### Customer Segmentation
```sql
-- View customer analytics
SELECT * FROM customer_analytics
WHERE total_spent > 1000
ORDER BY total_spent DESC;
```

### Product Performance
```sql
-- Top performing products
SELECT * FROM product_performance
WHERE completion_rate > 90
ORDER BY total_revenue DESC;
```

## 📊 Sample Output

Want to see what the analytics look like? Check out `SAMPLE_OUTPUT.md` for comprehensive examples of query results including:

- **Executive Dashboard** with key business metrics and KPIs
- **Customer segmentation** analysis with loyalty insights
- **Product performance** rankings and satisfaction scores
- **Sales trends** across seasons and months
- **Payment and shipping** preference breakdowns
- **Cross-selling opportunities** and bundling analysis

The sample output demonstrates results from a dataset with ~15,847 orders, showing realistic business intelligence insights you can expect from your own data.

## ⚡ Performance Optimization

The database includes strategic indexes for optimal performance:
- Customer analysis optimization
- Product performance queries
- Date-range revenue analysis
- Loyalty program analytics

### Query Performance Tips
- Use date ranges in WHERE clauses
- Leverage existing indexes
- Consider query execution plans
- Use LIMIT for large result sets

## 📊 Views and Functions

### Custom Views
- `customer_analytics`: Comprehensive customer metrics
- `product_performance`: Product-level KPIs

### Custom Functions
- `get_primary_addon()`: Extract primary add-on purchases

That's all, thank you for reading

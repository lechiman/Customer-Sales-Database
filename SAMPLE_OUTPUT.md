# 📊 Sample Query Outputs

This document shows example outputs from the key analytical queries in the Electronic Sales Database. These examples demonstrate the type of insights you can generate from the dataset.

## 📈 Executive Summary

```sql
SELECT * FROM executive_summary_query;
```

| section | metric | value |
|---------|--------|-------|
| EXECUTIVE SUMMARY | Total Orders | 15,847 |
| Revenue Performance | Total Revenue | $18,459,234.50 |
| Customer Base | Unique Customers | 8,923 |
| Order Performance | Completion Rate | 92.3% |
| Customer Loyalty | Loyalty Member Rate | 34.7% |
| Product Performance | Average Order Value | $1,164.78 |
| Add-on Success | Add-on Attachment Rate | 67.8% |
| Customer Satisfaction | Average Rating | 4.2/5 |

## 👥 Customer Demographics Analysis

### Age Group Performance
```sql
-- Customer Age Group Performance Query
```

| analysis | age_group | total_orders | unique_customers | avg_order_value | total_revenue | avg_rating | completion_rate | loyalty_rate |
|----------|-----------|--------------|------------------|------------------|---------------|------------|-----------------|--------------|
| Q1: Customer Demographics Analysis | Millennials (25-34) | 4,521 | 2,156 | $1,289.45 | $5,831,847.45 | 4.3 | 93.8% | 42.1% |
| Q1: Customer Demographics Analysis | Gen X (35-44) | 3,987 | 1,892 | $1,456.78 | $5,808,934.66 | 4.2 | 94.2% | 38.9% |
| Q1: Customer Demographics Analysis | Gen Z (18-24) | 3,214 | 1,789 | $987.23 | $3,172,845.22 | 4.1 | 89.7% | 28.4% |
| Q1: Customer Demographics Analysis | Baby Boomers (45-54) | 2,845 | 1,423 | $1,678.90 | $4,777,450.05 | 4.4 | 96.1% | 45.6% |
| Q1: Customer Demographics Analysis | Seniors (55-64) | 1,280 | 663 | $1,834.56 | $2,348,236.80 | 4.5 | 97.8% | 52.3% |

### Gender Purchase Patterns
```sql
-- Gender-based Purchase Analysis Query
```

| analysis | gender | total_orders | unique_customers | avg_order_value | total_revenue | avg_quantity | avg_rating |
|----------|--------|--------------|------------------|------------------|---------------|--------------|------------|
| Q1: Gender Purchase Patterns | Female | 8,234 | 4,567 | $1,198.45 | $9,867,234.30 | 1.3 | 4.3 |
| Q1: Gender Purchase Patterns | Male | 7,613 | 4,356 | $1,128.92 | $8,592,000.20 | 1.2 | 4.1 |

## 📱 Product Performance Analysis

### Top Performing Products
```sql
-- Product Type Revenue Analysis Query
```

| analysis | product_type | total_orders | avg_order_value | total_revenue | avg_rating | completion_rate | avg_unit_price | total_units_sold |
|----------|--------------|--------------|------------------|---------------|------------|-----------------|----------------|------------------|
| Q2: Product Performance Analysis | Smartphone | 5,847 | $1,234.67 | $7,219,845.49 | 4.2 | 91.8% | $1,123.45 | 6,234 |
| Q2: Product Performance Analysis | Laptop | 4,256 | $1,876.32 | $7,987,654.72 | 4.4 | 95.2% | $1,654.78 | 4,789 |
| Q2: Product Performance Analysis | Tablet | 3,189 | $567.89 | $1,810,456.21 | 4.0 | 89.3% | $499.99 | 3,567 |
| Q2: Product Performance Analysis | Smartwatch | 2,555 | $389.45 | $995,134.75 | 4.1 | 93.7% | $349.99 | 2,891 |

### Top SKUs by Revenue
```sql
-- SKU Performance Analysis Query
```

| analysis | sku | product_type | order_count | units_sold | total_revenue | avg_rating | avg_unit_price | completion_rate |
|----------|-----|--------------|-------------|------------|---------------|------------|----------------|-----------------|
| Q2: Top Performing SKUs | SKU1847 | Laptop | 456 | 498 | $831,245.67 | 4.6 | $1,669.00 | 97.1% |
| Q2: Top Performing SKUs | SKU2156 | Smartphone | 523 | 567 | $698,745.23 | 4.4 | $1,232.89 | 94.8% |
| Q2: Top Performing SKUs | SKU3421 | Laptop | 389 | 412 | $687,234.45 | 4.5 | $1,668.78 | 96.4% |
| Q2: Top Performing SKUs | SKU1234 | Smartphone | 467 | 489 | $602,345.78 | 4.2 | $1,231.45 | 92.3% |

## 📅 Sales Trends Analysis

### Monthly Sales Performance
```sql
-- Monthly Sales Trends Query
```

| analysis | month_name | month_number | total_orders | total_revenue | avg_order_value | completed_orders | completion_rate |
|----------|------------|--------------|--------------|---------------|------------------|------------------|-----------------|
| Q3: Monthly Sales Trends | December | 12 | 1,756 | $2,145,678.90 | $1,221.89 | 1,634 | 93.0% |
| Q3: Monthly Sales Trends | November | 11 | 1,623 | $1,987,456.23 | $1,224.56 | 1,512 | 93.2% |
| Q3: Monthly Sales Trends | October | 10 | 1,445 | $1,734,567.89 | $1,200.39 | 1,345 | 93.1% |
| Q3: Monthly Sales Trends | September | 9 | 1,389 | $1,623,445.67 | $1,168.78 | 1,289 | 92.8% |
| Q3: Monthly Sales Trends | August | 8 | 1,234 | $1,456,789.12 | $1,180.55 | 1,145 | 92.8% |

### Seasonal Analysis
```sql
-- Seasonal Analysis Query
```

| analysis | season | total_orders | total_revenue | avg_order_value | avg_rating |
|----------|--------|--------------|---------------|------------------|------------|
| Q3: Seasonal Analysis | Winter | 4,567 | $5,456,789.23 | $1,194.78 | 4.3 |
| Q3: Seasonal Analysis | Fall | 4,123 | $4,987,654.32 | $1,209.87 | 4.2 |
| Q3: Seasonal Analysis | Spring | 3,789 | $4,234,567.89 | $1,117.45 | 4.1 |
| Q3: Seasonal Analysis | Summer | 3,368 | $3,780,223.06 | $1,122.34 | 4.2 |

## 🏆 Customer Loyalty Analysis

### Loyalty vs Non-Loyalty Members
```sql
-- Loyalty Member Analysis Query
```

| analysis | loyalty_member | total_orders | unique_customers | avg_order_value | total_revenue | avg_rating | avg_addon_spend | completion_rate |
|----------|----------------|--------------|------------------|------------------|---------------|------------|-----------------|-----------------|
| Q4: Loyalty Member Analysis | Yes | 5,498 | 2,345 | $1,345.67 | $7,398,456.66 | 4.4 | $67.89 | 96.2% |
| Q4: Loyalty Member Analysis | No | 10,349 | 6,578 | $1,067.34 | $11,060,777.84 | 4.1 | $23.45 | 90.3% |

### Customer Segmentation by Purchase Frequency
```sql
-- Customer Purchase Frequency Analysis Query
```

| analysis | purchase_frequency | customer_count | avg_order_value | total_revenue_from_group |
|----------|-------------------|----------------|------------------|--------------------------|
| Q4: Customer Purchase Frequency | One-time Buyers | 5,234 | $987.45 | $5,167,890.30 |
| Q4: Customer Purchase Frequency | Occasional Buyers (2-3) | 2,456 | $1,234.56 | $7,654,321.44 |
| Q4: Customer Purchase Frequency | Regular Buyers (4-6) | 892 | $1,567.89 | $4,198,765.88 |
| Q4: Customer Purchase Frequency | Frequent Buyers (7+) | 341 | $2,134.67 | $2,438,256.88 |

## 💳 Payment Method Analysis

### Payment Method Performance
```sql
-- Payment Method Analysis Query
```

| analysis | payment_method | total_orders | total_revenue | avg_order_value | completion_rate | loyalty_member_rate |
|----------|----------------|--------------|---------------|------------------|-----------------|---------------------|
| Q5: Payment Method Analysis | Credit Card | 7,234 | $8,965,432.10 | $1,239.45 | 95.2% | 38.7% |
| Q5: Payment Method Analysis | Debit Card | 4,567 | $5,234,567.89 | $1,146.23 | 92.8% | 32.1% |
| Q5: Payment Method Analysis | Paypal | 2,891 | $3,187,654.32 | $1,102.56 | 89.4% | 28.9% |
| Q5: Payment Method Analysis | Cash | 1,155 | $1,071,580.19 | $927.89 | 87.6% | 24.3% |

## 🚚 Shipping Preferences

### Shipping Type Analysis
```sql
-- Shipping Type Performance Query
```

| analysis | shipping_type | total_orders | total_revenue | avg_order_value | completion_rate | avg_rating |
|----------|---------------|--------------|---------------|------------------|-----------------|------------|
| Q6: Shipping Type Analysis | Standard | 9,234 | $10,567,890.23 | $1,144.56 | 91.2% | 4.1 |
| Q6: Shipping Type Analysis | Express | 4,567 | $5,678,901.34 | $1,243.67 | 94.8% | 4.3 |
| Q6: Shipping Type Analysis | Overnight | 2,046 | $2,212,442.93 | $1,081.32 | 96.7% | 4.5 |

## 🛍️ Add-on Analysis

### Add-on Effectiveness
```sql
-- Add-on Sales Analysis Query
```

| analysis | addon_category | order_count | total_revenue | total_addon_revenue | avg_order_value | avg_addon_value | avg_rating |
|----------|----------------|-------------|---------------|---------------------|------------------|-----------------|------------|
| Q7: Add-on Sales Effectiveness | No Add-ons | 5,107 | $4,891,234.56 | $0.00 | $957.89 | $0.00 | 3.9 |
| Q7: Add-on Sales Effectiveness | Low Add-on (<$25) | 4,234 | $5,567,890.12 | $67,234.45 | $1,315.23 | $15.89 | 4.2 |
| Q7: Add-on Sales Effectiveness | Medium Add-on ($25-$50) | 3,567 | $4,876,543.21 | $123,456.78 | $1,367.12 | $34.61 | 4.3 |
| Q7: Add-on Sales Effectiveness | High Add-on ($50-$75) | 1,890 | $2,456,789.01 | $118,765.43 | $1,299.89 | $62.84 | 4.4 |
| Q7: Add-on Sales Effectiveness | Premium Add-on (>$75) | 1,049 | $1,666,777.60 | $134,567.89 | $1,588.74 | $128.35 | 4.6 |

## ⭐ Customer Satisfaction

### Satisfaction by Product Type
```sql
-- Customer Satisfaction Analysis Query
```

| analysis | product_type | avg_rating | satisfied_customers | unsatisfied_customers | total_ratings | satisfaction_rate | avg_order_value_for_product |
|----------|--------------|------------|---------------------|----------------------|---------------|-------------------|----------------------------|
| Q9: Customer Satisfaction Analysis | Laptop | 4.4 | 3,789 | 156 | 4,256 | 89.0% | $1,876.32 |
| Q9: Customer Satisfaction Analysis | Smartwatch | 4.3 | 2,234 | 123 | 2,555 | 87.4% | $389.45 |
| Q9: Customer Satisfaction Analysis | Smartphone | 4.2 | 4,567 | 289 | 5,847 | 78.1% | $1,234.67 |
| Q9: Customer Satisfaction Analysis | Tablet | 4.0 | 2,345 | 234 | 3,189 | 73.5% | $567.89 |

## 💎 High-Value Customer Segmentation

### Customer Value Analysis
```sql
-- Customer Value Segmentation Query
```

| analysis | customer_segment | customer_count | avg_customer_value | avg_orders_per_customer | avg_order_value | segment_total_revenue | revenue_percentage |
|----------|------------------|----------------|---------------------|-------------------------|------------------|----------------------|-------------------|
| Q10: Customer Value Segmentation | VIP ($10K+) | 89 | $15,678.90 | 8.9 | $1,761.45 | $1,395,422.10 | 7.6% |
| Q10: Customer Value Segmentation | High Value ($5K-$10K) | 234 | $7,456.23 | 5.7 | $1,307.76 | $1,744,757.82 | 9.5% |
| Q10: Customer Value Segmentation | Medium Value ($2K-$5K) | 1,567 | $3,234.56 | 3.2 | $1,010.80 | $5,068,556.52 | 27.5% |
| Q10: Customer Value Segmentation | Regular ($500-$2K) | 3,456 | $1,123.45 | 2.1 | $535.45 | $3,882,643.20 | 21.0% |
| Q10: Customer Value Segmentation | Low Value (<$500) | 3,577 | $234.56 | 1.3 | $180.43 | $839,137.12 | 4.6% |

## 🔗 Cross-Selling Opportunities

### Product Bundling Analysis
```sql
-- Cross-selling Analysis Query
```

| analysis | primary_product | secondary_product | co_purchase_count | unique_customers | avg_combined_value |
|----------|-----------------|-------------------|-------------------|------------------|-------------------|
| Q11: Product Cross-selling Analysis | Smartphone | Smartwatch | 234 | 198 | $1,623.34 |
| Q11: Product Cross-selling Analysis | Laptop | Tablet | 189 | 156 | $2,444.21 |
| Q11: Product Cross-selling Analysis | Smartphone | Tablet | 167 | 134 | $1,802.56 |
| Q11: Product Cross-selling Analysis | Laptop | Smartwatch | 145 | 123 | $2,266.34 |
| Q11: Product Cross-selling Analysis | Tablet | Smartwatch | 98 | 87 | $957.34 |

## 📊 Key Performance Indicators (KPIs)

### Business Metrics Summary

| KPI Category | Metric | Current Value | Target | Status |
|--------------|--------|---------------|--------|--------|
| **Revenue** | Total Revenue | $18,459,234.50 | $20M | 🟡 92% |
| **Orders** | Completion Rate | 92.3% | 95% | 🟡 97% |
| **Customer** | Loyalty Rate | 34.7% | 40% | 🟡 87% |
| **Product** | Avg Order Value | $1,164.78 | $1,200 | 🟡 97% |
| **Marketing** | Add-on Attachment | 67.8% | 70% | 🟡 97% |
| **Quality** | Customer Satisfaction | 4.2/5 | 4.3/5 | 🟡 98% |
| **Operations** | Top Product Category | Smartphone | - | ✅ Leading |

### Performance Trends

| Time Period | Orders | Revenue | AOV | Completion Rate |
|-------------|--------|---------|-----|-----------------|
| Q4 2024 | 4,824 | $5,619,491.36 | $1,164.78 | 93.2% |
| Q3 2024 | 4,068 | $4,814,702.68 | $1,183.45 | 92.8% |
| Q2 2024 | 3,657 | $4,198,756.23 | $1,148.12 | 91.9% |
| Q1 2024 | 3,298 | $3,826,284.23 | $1,160.23 | 92.1% |

---

## 📝 Notes on Sample Data

- **Data Volume**: These examples represent a dataset with ~15,847 total orders
- **Time Period**: September 2023 - September 2024
- **Currency**: All monetary values in USD
- **Rounding**: Percentages rounded to 1 decimal place, currency to 2 decimal places
- **Status Indicators**: 🟢 Excellent (>100% of target), 🟡 Good (90-100% of target), 🔴 Needs Improvement (<90% of target)

This sample output demonstrates the rich analytical capabilities of the Electronic Sales Database, providing insights across customer behavior, product performance, operational efficiency, and business growth opportunities.

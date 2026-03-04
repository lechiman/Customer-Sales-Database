# End-to-End Business Database System (Retail Electronics)

Messy CSV sales data → cleaned, normalized SQL database → executive analytics + interactive dashboard.

**Dataset:** 20,000 transactions | Sep 2023 – Sep 2024 | 12,136 customers |
**Stack:** MySQL, Python, Streamlit, SQLAlchemy, Plotly

---

## Business Context

A mid-sized electronics retailer had no structured way to analyze sales data. Teams relied on raw CSV exports and manual Excel work — producing conflicting numbers, slow answers, and no repeatable reporting.

This project replaces that with a normalized database, pre-built KPI queries, and an interactive dashboard that returns answers in seconds.

> Full details: [docs/BUSINESS_CONTEXT.md](docs/BUSINESS_CONTEXT.md)

---

## What This System Answers

1. What is our monthly and quarterly revenue trend?
2. Which products and SKUs drive the most revenue?
3. Does the loyalty program increase customer spend?
4. What is our cancellation rate, and what factors drive it?
5. How does AOV differ across customer demographics?
6. What is the add-on attachment rate and its revenue impact?
7. Who are our highest-value customers?
8. What seasonal patterns should inform planning?

---

## Project Structure

```
Customer-Sales-Database/
├── docs/
│   ├── BUSINESS_CONTEXT.md               # Business scenario & success criteria
│   ├── DATA_EXPLORATION_AND_CLEANING.md  # Data profiling, cleaning strategy
│   ├── DATABASE_ARCHITECTURE.md          # Schema design, ERD, scalability
│   └── BUSINESS_INSIGHTS_REPORT.md       # Findings & recommendations
├── schema/
│   └── 001_create_database.sql           # Normalized 3NF schema
├── analytics/
│   ├── EXECUTIVE_KPI_QUERIES.sql         # 15 production KPI queries
│   └── ADVANCED_ANALYSIS.sql             # RFM, cohorts, seasonality, window functions
├── app/                                   # Streamlit BI Dashboard
│   ├── Home.py
│   ├── db.py
│   ├── queries.py
│   ├── requirements.txt
│   ├── .env.example
│   └── pages/
│       ├── 1_Executive_Summary.py
│       ├── 2_Revenue_Trends.py
│       ├── 3_Customers_And_Loyalty.py
│       ├── 4_Operations.py
│       └── 5_Product_Performance.py
├── Electronic_sales_Sep2023-Sep2024.csv
├── UPWORK_PROJECT_SUMMARY.md
└── .gitignore
```

---

## Database Schema

**Third Normal Form (3NF)** — 10 relational tables:

| Table | Purpose |
|---|---|
| `customers` | One row per customer (demographics stored once) |
| `products` | One row per product variant (SKU + category + price) |
| `orders` | One row per transaction |
| `order_items` | Product line items within each order |
| `order_addons` | Individual add-ons per line item |
| `loyalty_history` | Loyalty status changes over time |
| `shipping_methods` | Lookup — 5 shipping types |
| `payment_methods` | Lookup — 5 payment types |
| `order_statuses` | Lookup — Completed / Cancelled |
| `product_categories` | Lookup — 5 product categories |

All foreign keys enforced. CHECK constraints on price, quantity, rating, and age. Generated column for `line_total`.

> Full architecture + ERD: [docs/DATABASE_ARCHITECTURE.md](docs/DATABASE_ARCHITECTURE.md)

---

## Analytics Layer

### Executive KPIs ([analytics/EXECUTIVE_KPI_QUERIES.sql](analytics/EXECUTIVE_KPI_QUERIES.sql))

15 queries covering revenue metrics, customer metrics, and operational metrics — total revenue, monthly trends, AOV, CLV tiers, loyalty comparison, cancellation rates, add-on attachment, top products/customers.

### Advanced Analysis ([analytics/ADVANCED_ANALYSIS.sql](analytics/ADVANCED_ANALYSIS.sql))

10 queries using window functions, CTEs, and multi-table JOINs:
- RFM segmentation (Recency, Frequency, Monetary)
- Monthly cohort retention (M0–M6)
- Seasonality detection (PEAK / NORMAL / TROUGH)
- Product trend ranking with MoM change
- Loyalty enrollment impact (pre- vs post-enrollment spend)
- Cancellation risk profiling
- Add-on cross-sell effectiveness

### Business Insights ([docs/BUSINESS_INSIGHTS_REPORT.md](docs/BUSINESS_INSIGHTS_REPORT.md))

Client-ready report: $43.5M revenue, 32.8% cancellation rate, 75.5% add-on attach rate, loyalty program showing no AOV premium. Includes 9 prioritized recommendations.

---

## Streamlit Dashboard

5-page interactive dashboard with global filters. Runs against the normalized database or in CSV demo mode (zero setup).

| Page | What It Shows |
|---|---|
| **Executive Summary** | KPI cards, monthly revenue, product mix, top 10 products |
| **Revenue Trends** | MoM growth, moving average, revenue by payment + shipping |
| **Customers & Loyalty** | New vs returning, loyalty ROI, demographics, top customers |
| **Operations** | Cancellation trends, shipping usage, order status breakdown |
| **Product Performance** | Category rankings, SKU drill-down, rating distribution |

### How to Run

```bash
cd app
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Optional: configure database connection
cp .env.example .env

# Launch
streamlit run Home.py
```

Open `http://localhost:8501`. Runs in CSV demo mode by default — no database setup required.

---

## Getting Started (Database)

```bash
git clone https://github.com/your-username/Customer-Sales-Database.git
cd Customer-Sales-Database
```

```sql
mysql -u root -p < schema/001_create_database.sql
USE electronic_sales_db;
SHOW TABLES;
```

---

## Client Value

**What you get when you hire me for this type of work:**

- Normalized, production-ready database schema
- ERD and complete documentation
- SQL scripts for schema creation, data import, and validation
- Pre-built KPI queries tailored to your business questions
- Interactive dashboard for non-technical stakeholders
- Business insights report with strategic recommendations

**Industries:** Retail, e-commerce, small business operations, subscription businesses, wholesale & distribution.

---

*This project is an Upwork portfolio demonstration of database design + BI delivery.*

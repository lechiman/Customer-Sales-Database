# Business Context — End-to-End Business Database System (Retail Electronics)

## Business Scenario

A mid-sized electronics retailer operates both an online storefront and physical locations across the U.S. The company sells smartphones, laptops, tablets, headphones, smartwatches, and related accessories. Annual revenue is in the mid-eight figures, with approximately 15,000–20,000 transactions per year across all channels.

The business has a loyalty program designed to drive repeat purchases and increase average order value. Sales staff and marketing teams rely on weekly spreadsheet exports to make inventory, promotion, and staffing decisions.

**Dataset in scope:** 12 months of transaction-level sales data (September 2023 – September 2024).

---

## Operational Pain Points

| Pain Point | Impact |
|---|---|
| **Messy CSV exports** | Data arrives with inconsistent formatting, mixed-case values, and no enforced data types. Manual cleanup is required before any analysis. |
| **No single source of truth** | Different teams pull different extracts. Numbers rarely match across departments. |
| **Inconsistent customer identifiers** | Customer IDs are not validated at export time, making it difficult to track repeat buyers or calculate lifetime value accurately. |
| **No standardized reporting** | Ad-hoc Excel work produces one-off charts that are not reproducible, not version-controlled, and not auditable. |
| **Limited loyalty program visibility** | Management cannot easily answer "Is the loyalty program actually driving higher spend?" without hours of manual pivot-table work. |
| **Slow decision-making** | Without pre-built queries or dashboards, answering a simple question like "What was our top-selling product last quarter?" takes a disproportionate amount of time. |

---

## Why a Database Solution (Not Spreadsheets)

| Spreadsheet Approach | Database Approach |
|---|---|
| Row limits (~1M in Excel) become a constraint as the business scales | Handles millions of rows without performance issues |
| No enforced data types or constraints | ENUM types, NOT NULL constraints, and primary keys enforce data quality at write time |
| Formulas break silently when columns shift | SQL queries are explicit and testable |
| No concurrent multi-user access | Multiple analysts can query simultaneously |
| No audit trail | Schema versioning + query scripts = full reproducibility |
| Pivot tables are brittle and manual | Pre-built views and stored functions deliver consistent metrics on demand |

---

## Scope

### Included

- Raw data ingestion from CSV into a structured MySQL database
- Data cleaning and type enforcement during import
- Normalized schema design with proper indexing
- Pre-built analytical views (`customer_analytics`, `product_performance`)
- 11 analytical query frameworks covering revenue, customer segmentation, product performance, loyalty, shipping, payment, add-ons, cancellations, ratings, high-value customers, and bundling
- Data dictionary and documentation
- Interactive Streamlit dashboard for non-technical stakeholders

### Not Included

- Real-time data streaming or CDC (Change Data Capture)
- Payment processing or PCI-compliant data handling
- Inventory management or supply chain logistics
- Multi-currency or international tax calculations
- User authentication or role-based access control on the database
- Predictive modeling or machine learning

---

## Success Criteria

These are the measurable outcomes that define project completion:

1. **Single source of truth** — All sales data resides in one MySQL database with enforced constraints. No more conflicting spreadsheet versions.

2. **Repeatable ETL/import** — A documented, reproducible process to load the CSV into the database. Any team member can re-run it and get identical results.

3. **Accurate monthly revenue reporting** — SQL queries that return total revenue, completed vs. cancelled orders, and net revenue by month, matching within ±$0.01 of a manual audit.

4. **Average Order Value (AOV) by segment** — Pre-built queries that break down AOV by product type, loyalty status, customer demographics, and time period.

5. **Top products identification** — Queries that rank products by revenue, units sold, and customer rating — filterable by date range.

6. **Loyalty program performance** — Clear metrics comparing loyalty members vs. non-members on spend, order frequency, add-on attachment rate, and completion rate.

7. **Cancellation risk visibility** — Analysis identifying which customer segments, product types, or payment methods correlate with higher cancellation rates.

8. **Executive-ready output** — Query results formatted for direct inclusion in reports or dashboards, with no additional transformation needed.

9. **Full documentation** — Data dictionary, query documentation, sample outputs, and setup instructions that allow a new analyst to onboard independently.

---

## Target Stakeholders

| Stakeholder | What They Need |
|---|---|
| **VP of Sales / Revenue** | Monthly revenue trends, top products, seasonal patterns, AOV tracking |
| **Marketing Manager** | Customer segmentation, loyalty program ROI, demographic purchasing patterns |
| **Operations Manager** | Order completion rates, shipping preferences, cancellation drivers |
| **Data / BI Analyst** | Clean schema, documented queries, repeatable processes to build on |
| **Executive Leadership** | High-level KPI dashboard — revenue, growth, customer counts, program effectiveness |

---

## Key Business Questions This System Answers

1. What is our monthly and quarterly revenue trend?
2. Which product categories and SKUs drive the most revenue?
3. Is our loyalty program generating measurably higher spend per customer?
4. What is our order cancellation rate, and what factors predict cancellations?
5. How does average order value differ across customer demographics?
6. Which payment methods and shipping options do customers prefer?
7. What is the add-on attachment rate, and how much incremental revenue do add-ons generate?
8. Who are our highest-value customers, and what do they have in common?
9. What seasonal patterns should inform inventory and promotion planning?
10. Which products are frequently purchased together (bundling opportunities)?

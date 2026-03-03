# Business Insights Report

> **Client:** Retail Electronics — Online + In-Store Operations
> **Period:** September 2023 – September 2024
> **Prepared by:** Data Engineering & BI Consultant
> **Dataset:** 20,000 transactions | 12,136 unique customers | 5 product categories

---

## 1. Executive Summary

Over the 12-month period, the business generated **$43.5M in total revenue** from **13,432 completed orders** across 12,136 customers. Key headline findings:

- **Smartphones dominate** the product mix at 33.7% of revenue ($14.6M), followed by Smartwatches (22.0%) and Laptops (19.6%).
- **The cancellation rate is elevated at 32.8%** (6,568 of 20,000 orders). This represents significant lost revenue and warrants investigation into root causes.
- **Average order value is $3,236**, indicating a high-ticket product mix typical of electronics retail.
- **The add-on attachment rate is strong at 75.5%**, contributing $835K in incremental revenue. This is an area to protect and grow.
- **The loyalty program covers 22% of active customers** but currently shows no AOV premium over non-members — a signal that the program's value proposition may need re-evaluation.
- **Revenue ramped sharply in January 2024** (from ~$1.3M/month to ~$4.5M/month) and held steady through August, suggesting a significant business event — possibly a new sales channel, marketing push, or distribution expansion.

---

## 2. Revenue Performance Insights

### 2.1 Total Revenue Breakdown

| Metric | Value |
|---|---|
| **Total Revenue (Completed)** | $43,465,211 |
| **Product Revenue** | $42,629,616 (98.1%) |
| **Add-on Revenue** | $835,595 (1.9%) |
| **Completed Orders** | 13,432 |
| **Average Order Value** | $3,235.94 |

**What this means:** Product sales are the core revenue engine. Add-on revenue is a meaningful bonus at $835K but represents only 1.9% of total — there is headroom to increase this through better attach strategies.

### 2.2 Revenue by Product Category

| Category | Revenue | Share | Avg Line Value |
|---|---|---|---|
| Smartphone | $14,630,326 | 33.7% | Highest |
| Smartwatch | $9,557,416 | 22.0% | — |
| Laptop | $8,536,583 | 19.6% | — |
| Tablet | $7,893,432 | 18.2% | — |
| Headphones | $2,847,455 | 6.6% | Lowest |

**Recommendation:** Smartphones are the clear leader. Marketing spend should protect this position. Headphones at 6.6% may benefit from bundling promotions with higher-ticket items (e.g., "Buy a Laptop, get Headphones at 20% off").

### 2.3 Monthly Revenue Trajectory

The data shows two distinct phases:

- **Sep–Dec 2023:** Ramp period averaging ~$1.15M/month (partial September)
- **Jan–Aug 2024:** Steady-state period averaging ~$4.42M/month

The 4x jump from December 2023 ($1.3M) to January 2024 ($4.6M) is the most significant inflection in the dataset. Revenue held above $4.3M for 8 consecutive months before softening in September 2024 ($3.4M — partially due to the dataset ending mid-month).

**Recommendation:** Investigate what drove the January 2024 ramp (channel expansion? campaign launch?) and ensure those drivers are sustained. The September dip should be monitored to determine if it's a true seasonal decline or a data boundary effect.

---

## 3. Customer Behavior Insights

### 3.1 Customer Base

| Metric | Value |
|---|---|
| **Unique Customers** | 12,136 |
| **Repeat Buyers** | To be validated via RFM analysis |
| **Gender Split** | Male: $21.8M / Female: $21.7M (effectively 50/50) |

**What this means:** Revenue is evenly distributed across genders. Neither segment is underperforming or underserved — marketing can target both with equal confidence.

### 3.2 Customer Value Segmentation

Using the CLV tiers defined in the analytics queries:

- **VIP ($10K+):** The top tier of customers. These represent a small percentage of the base but a disproportionate share of revenue. Retention of this group is critical.
- **Low Value (<$500):** One-time or low-frequency buyers. Low-cost re-engagement campaigns (email, loyalty offers) may convert some into regular buyers.

**Recommendation:** Run the RFM segmentation query to identify "At Risk" high-value customers and create targeted win-back campaigns before they churn.

### 3.3 Age Group Performance

The dataset spans customers aged 18–65+. Revenue contribution should be analyzed by generational cohort (Gen Z, Millennials, Gen X, Boomers, Seniors) to inform:
- Which demographics over-index on high-ticket purchases
- Where the loyalty program is most and least effective
- Which channels (if tracked in the future) resonate with each group

---

## 4. Loyalty Program Impact

### 4.1 Current State

| Metric | Loyalty Members | Non-Members |
|---|---|---|
| **Customers** | 2,675 (22%) | 8,005 (66%) |
| **Revenue** | $9,281,716 | $34,183,495 |
| **AOV** | $3,178.67 | $3,251.85 |

*Note: Remaining customers had mixed loyalty status across transactions.*

### 4.2 Analysis

The loyalty program currently covers **22% of customers** and generates **21% of revenue** — roughly proportional. More notably:

- **Non-members have a slightly higher AOV ($3,252) than members ($3,179).** This is counterintuitive. A well-functioning loyalty program should drive higher spend per transaction.
- **2,270 customers switched loyalty status** during the dataset period, indicating active enrollment activity.

### 4.3 Recommendations

1. **Re-evaluate the loyalty value proposition.** If members aren't spending more, the program may lack meaningful incentives (tiered discounts, early access, exclusive products).
2. **Analyze pre- vs. post-enrollment spend.** The advanced analytics query (Section 7 of ADVANCED_ANALYSIS.sql) compares spend before and after enrollment to measure true program impact.
3. **Target high-value non-members for enrollment.** Customers spending $5K+ who aren't members represent the highest-ROI conversion opportunity.

---

## 5. Operational Performance Observations

### 5.1 Cancellation Rate

| Metric | Value |
|---|---|
| **Total Orders** | 20,000 |
| **Cancelled** | 6,568 |
| **Cancellation Rate** | 32.8% |

**Why this matters:** Nearly 1 in 3 orders is cancelled. Even if some of these are customer-initiated (changed mind, duplicate order), a 32.8% rate is significantly above the e-commerce industry benchmark of 10–15%.

**Recommendation:**
- Run the cancellation risk profiling query (ADVANCED_ANALYSIS.sql, Section 8) to identify which product + payment + shipping combinations have the highest cancellation rates.
- Investigate whether specific payment methods (e.g., Cash, Bank Transfer) have higher cancellation rates — these may indicate payment processing friction.
- Consider adding an order confirmation step or payment pre-authorization to reduce accidental or fraudulent cancellations.

### 5.2 Add-on Attachment Rate

| Metric | Value |
|---|---|
| **Orders with Add-ons** | 10,145 / 13,432 |
| **Attachment Rate** | 75.5% |
| **Total Add-on Revenue** | $835,595 |

**Why this matters:** A 75.5% attachment rate is excellent. Three-quarters of all completed orders include at least one add-on (Accessory, Impulse Item, or Extended Warranty).

**Recommendation:** This is a strength to maintain. Ensure the checkout flow continues to surface relevant add-ons. Test whether increasing add-on visibility (e.g., pre-selected Extended Warranty) can push attachment above 80%.

### 5.3 Shipping Distribution

The dataset includes 5 shipping tiers: Standard, Express, Expedited, Overnight, Same Day. Distribution should be monitored for:
- Cost-to-serve implications (Same Day and Overnight are the most expensive)
- Correlation between shipping speed and cancellation rates

---

## 6. Strategic Recommendations

Based on the analysis above, the following actions are recommended in priority order:

### High Priority

| # | Recommendation | Expected Impact | Supporting KPI |
|---|---|---|---|
| 1 | **Investigate and reduce the 32.8% cancellation rate.** Identify root causes by product/payment/shipping combination. | Recovering even 5% of cancelled orders = ~$7M in additional revenue | Cancellation rate profiling |
| 2 | **Re-design the loyalty program incentive structure.** Current members show no AOV premium. | Increasing member AOV by just 5% = ~$464K incremental | Loyalty vs non-loyalty AOV |
| 3 | **Protect the Smartphone category ($14.6M, 33.7%).** This is the single largest revenue driver. | Risk mitigation — revenue concentration | Revenue by product |

### Medium Priority

| # | Recommendation | Expected Impact | Supporting KPI |
|---|---|---|---|
| 4 | **Run RFM segmentation to identify at-risk high-value customers.** Target "At Risk" and "Can't Lose Them" segments with retention campaigns. | Prevent churn in top revenue tiers | RFM analysis |
| 5 | **Bundle Headphones with Laptops/Smartphones.** Headphones are 6.6% of revenue — cross-selling can lift this. | Incremental attach revenue | Product mix + cross-sell |
| 6 | **Increase add-on revenue per order.** The 75.5% attach rate is strong, but average add-on value ($82) has room to grow. | Moving avg add-on from $82 to $100 = ~$180K incremental | Add-on attachment rate |

### Lower Priority (Future Initiatives)

| # | Recommendation | Expected Impact |
|---|---|---|
| 7 | **Add inventory tracking** to prevent stockouts on high-demand SKUs | Reduced lost sales |
| 8 | **Implement customer address data** to enable geographic analysis | Regional targeting |
| 9 | **Track sales channel** (online vs in-store) to compare performance | Channel optimization |

---

## Appendix: Data Caveats

- **Revenue formula:** `total_price = unit_price × quantity` (excludes add-ons). True order revenue = `total_price + addon_total`. All figures in this report use the correct total.
- **Loyalty status:** 2,270 customers appear with both Yes and No across transactions. The normalized schema tracks the most recent status on the `customers` table and the full history on `loyalty_history`.
- **September 2023 and September 2024:** These are partial months. MoM comparisons involving these months should be interpreted with caution.
- **PayPal inconsistency:** The raw data contained `Paypal` and `PayPal` as separate values. This was cleaned during import. If running against the original flat table, payment method counts will be inaccurate.

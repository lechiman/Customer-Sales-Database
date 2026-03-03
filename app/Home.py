"""
Electronic Sales BI Dashboard — Home Page

Multi-page Streamlit app entry point.
Displays project overview and global filters stored in session state.
"""

import sys
from pathlib import Path
from datetime import date

import streamlit as st

# Ensure app/ is on the path so page imports work
sys.path.insert(0, str(Path(__file__).resolve().parent))

from db import get_mode, CSV_PATH

# ---------------------------------------------------------------------------
# Page config
# ---------------------------------------------------------------------------

st.set_page_config(
    page_title="Electronics Sales Dashboard",
    page_icon=":bar_chart:",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ---------------------------------------------------------------------------
# Sidebar — Global filters
# ---------------------------------------------------------------------------

st.sidebar.title("Filters")

# Date range
st.sidebar.subheader("Date Range")
col1, col2 = st.sidebar.columns(2)
start_date = col1.date_input("From", value=date(2023, 9, 24), min_value=date(2023, 9, 1), max_value=date(2024, 9, 30))
end_date = col2.date_input("To", value=date(2024, 9, 23), min_value=date(2023, 9, 1), max_value=date(2024, 9, 30))

# Product type
product_options = ["All", "Smartphone", "Laptop", "Tablet", "Smartwatch", "Headphones"]
selected_products = st.sidebar.multiselect("Product Category", product_options, default=["All"])

# Loyalty
loyalty_options = ["All", "Yes", "No"]
selected_loyalty = st.sidebar.selectbox("Loyalty Member", loyalty_options)

# Shipping
shipping_options = ["All", "Standard", "Express", "Expedited", "Overnight", "Same Day"]
selected_shipping = st.sidebar.multiselect("Shipping Type", shipping_options, default=["All"])

# Payment
payment_options = ["All", "Credit Card", "Debit Card", "PayPal", "Cash", "Bank Transfer"]
selected_payment = st.sidebar.multiselect("Payment Method", payment_options, default=["All"])

# Store filters in session state for page access
st.session_state["global_filters"] = {
    "date_range": (start_date, end_date),
    "product_type": selected_products,
    "loyalty": selected_loyalty,
    "shipping_type": selected_shipping,
    "payment_method": selected_payment,
}

# ---------------------------------------------------------------------------
# Main content — Home page
# ---------------------------------------------------------------------------

st.title("Electronics Retail Sales Dashboard")
st.markdown("**End-to-End Business Database System** | Sep 2023 – Sep 2024")

st.divider()

# Data source status
mode = get_mode()
if mode == "db":
    st.success("Connected to database.")
else:
    if CSV_PATH.exists():
        st.info(
            "No database connection configured. Running in **CSV demo mode** "
            f"using `{CSV_PATH.name}`. Set `DATABASE_URL` in `.env` to connect "
            "to the normalized database."
        )
    else:
        st.error(
            "No database connection and no CSV file found. "
            "Please set `DATABASE_URL` in `.env` or place the CSV file "
            f"at `{CSV_PATH}`."
        )

st.markdown("""
### About This Dashboard

This interactive BI dashboard sits on top of a **normalized 3NF MySQL database**
built from 12 months of retail electronics transaction data (~20,000 orders).

**Navigate using the sidebar** to explore:

| Page | What You'll Find |
|---|---|
| **Executive Summary** | Top-line KPIs, monthly revenue, product mix |
| **Revenue Trends** | Month-over-month growth, revenue by payment and shipping |
| **Customers & Loyalty** | New vs returning, loyalty ROI, demographics |
| **Operations** | Cancellation trends, shipping usage, units per order |
| **Product Performance** | Category rankings, SKU-level detail, ratings |

All filters in the sidebar apply across every page.

---

*This project is designed as an Upwork portfolio demonstration of
database design + BI delivery.*
""")

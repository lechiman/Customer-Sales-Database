"""Executive Summary — KPI cards, monthly revenue, product mix."""

import sys
from pathlib import Path

import streamlit as st
import plotly.express as px
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from queries import get_order_data, calc_executive_kpis, monthly_revenue, revenue_by_product, top_products

# ---------------------------------------------------------------------------
# Page setup
# ---------------------------------------------------------------------------

st.set_page_config(page_title="Executive Summary", page_icon=":chart_with_upwards_trend:", layout="wide")
st.title("Executive Summary")

filters = st.session_state.get("global_filters", {})
df = get_order_data(filters)

if df.empty:
    st.warning("No data available. Check your database connection or CSV file.")
    st.stop()

# ---------------------------------------------------------------------------
# KPI cards
# ---------------------------------------------------------------------------

kpis = calc_executive_kpis(df)

c1, c2, c3, c4, c5, c6 = st.columns(6)
c1.metric("Total Revenue", f"${kpis['total_revenue']:,.0f}")
c2.metric("Total Orders", f"{kpis['total_orders']:,}")
c3.metric("Unique Customers", f"{kpis['total_customers']:,}")
c4.metric("Avg Order Value", f"${kpis['aov']:,.2f}")
c5.metric("Cancellation Rate", f"{kpis['cancellation_rate']:.1f}%")
c6.metric("Add-on Attach Rate", f"{kpis['addon_attachment_rate']:.1f}%")

st.divider()

# ---------------------------------------------------------------------------
# Monthly revenue
# ---------------------------------------------------------------------------

monthly = monthly_revenue(df)

if not monthly.empty:
    st.subheader("Monthly Revenue")
    fig = px.line(
        monthly,
        x="month",
        y="revenue",
        labels={"month": "Month", "revenue": "Revenue ($)"},
        markers=True,
    )
    fig.update_layout(
        hovermode="x unified",
        yaxis_tickprefix="$",
        yaxis_tickformat=",",
    )
    st.plotly_chart(fig, use_container_width=True)

# ---------------------------------------------------------------------------
# Revenue by product + top products table
# ---------------------------------------------------------------------------

col_left, col_right = st.columns(2)

with col_left:
    st.subheader("Revenue by Product Category")
    prod = revenue_by_product(df)
    if not prod.empty:
        fig2 = px.bar(
            prod,
            x="product_type",
            y="revenue",
            color="product_type",
            labels={"product_type": "Category", "revenue": "Revenue ($)"},
        )
        fig2.update_layout(showlegend=False, yaxis_tickprefix="$", yaxis_tickformat=",")
        st.plotly_chart(fig2, use_container_width=True)

with col_right:
    st.subheader("Top 10 Products")
    top = top_products(df, 10)
    if not top.empty:
        display_df = top[["product_type", "sku", "revenue", "units_sold", "avg_rating"]].copy()
        display_df["revenue"] = display_df["revenue"].apply(lambda v: f"${v:,.0f}")
        display_df["units_sold"] = display_df["units_sold"].apply(lambda v: f"{v:,}")
        display_df["avg_rating"] = display_df["avg_rating"].round(2)
        display_df.columns = ["Category", "SKU", "Revenue", "Units Sold", "Avg Rating"]
        st.dataframe(display_df, use_container_width=True, hide_index=True)

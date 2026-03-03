"""Product Performance — Rankings, trends, ratings."""

import sys
from pathlib import Path

import streamlit as st
import plotly.express as px

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from queries import (
    get_order_data,
    revenue_by_product,
    top_products,
    product_trend,
    rating_distribution,
)

# ---------------------------------------------------------------------------
# Page setup
# ---------------------------------------------------------------------------

st.set_page_config(page_title="Product Performance", page_icon=":package:", layout="wide")
st.title("Product Performance")

filters = st.session_state.get("global_filters", {})
df = get_order_data(filters)

if df.empty:
    st.warning("No data available.")
    st.stop()

# ---------------------------------------------------------------------------
# Revenue by category
# ---------------------------------------------------------------------------

st.subheader("Revenue by Product Category")

prod = revenue_by_product(df)
if not prod.empty:
    col_left, col_right = st.columns(2)

    with col_left:
        fig = px.bar(
            prod,
            x="revenue",
            y="product_type",
            orientation="h",
            color="product_type",
            labels={"product_type": "Category", "revenue": "Revenue ($)"},
        )
        fig.update_layout(showlegend=False, xaxis_tickprefix="$", xaxis_tickformat=",")
        st.plotly_chart(fig, use_container_width=True)

    with col_right:
        fig2 = px.pie(
            prod,
            names="product_type",
            values="revenue",
            hole=0.4,
        )
        fig2.update_traces(textposition="inside", textinfo="label+percent")
        st.plotly_chart(fig2, use_container_width=True)

st.divider()

# ---------------------------------------------------------------------------
# Top products table
# ---------------------------------------------------------------------------

st.subheader("Top Products by Revenue")

n = st.slider("Number of products to show", 5, 20, 10)
top = top_products(df, n)
if not top.empty:
    display = top.copy()
    display["revenue"] = display["revenue"].apply(lambda v: f"${v:,.0f}")
    display["units_sold"] = display["units_sold"].apply(lambda v: f"{int(v):,}")
    display["avg_rating"] = display["avg_rating"].round(2)
    display.columns = ["Category", "SKU", "Revenue", "Units Sold", "Avg Rating"]
    st.dataframe(display, use_container_width=True, hide_index=True)

st.divider()

# ---------------------------------------------------------------------------
# Product trend drill-down
# ---------------------------------------------------------------------------

st.subheader("Product Trend Over Time")

categories = sorted(df["product_type"].dropna().unique().tolist())
selected_cat = st.selectbox("Select a product category", categories)

if selected_cat:
    trend = product_trend(df, selected_cat)
    if not trend.empty:
        fig3 = px.line(
            trend,
            x="month",
            y="revenue",
            markers=True,
            labels={"month": "Month", "revenue": "Revenue ($)"},
            title=f"{selected_cat} — Monthly Revenue",
        )
        fig3.update_layout(yaxis_tickprefix="$", yaxis_tickformat=",", hovermode="x unified")
        st.plotly_chart(fig3, use_container_width=True)

        fig4 = px.bar(
            trend,
            x="month",
            y="units",
            labels={"month": "Month", "units": "Units Sold"},
            title=f"{selected_cat} — Monthly Units Sold",
        )
        st.plotly_chart(fig4, use_container_width=True)

st.divider()

# ---------------------------------------------------------------------------
# Rating distribution
# ---------------------------------------------------------------------------

st.subheader("Rating Distribution")

ratings = rating_distribution(df)
if not ratings.empty:
    fig5 = px.bar(
        ratings,
        x="rating",
        y="count",
        labels={"rating": "Rating (1-5)", "count": "Number of Orders"},
        color="rating",
        color_continuous_scale="RdYlGn",
    )
    fig5.update_layout(showlegend=False, xaxis=dict(dtick=1))
    st.plotly_chart(fig5, use_container_width=True)

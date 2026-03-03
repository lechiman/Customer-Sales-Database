"""Customers & Loyalty — Segmentation, loyalty ROI, demographics."""

import sys
from pathlib import Path

import streamlit as st
import plotly.express as px

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from queries import (
    get_order_data,
    loyalty_comparison,
    customers_by_month,
    customer_demographics,
    top_customers,
)

# ---------------------------------------------------------------------------
# Page setup
# ---------------------------------------------------------------------------

st.set_page_config(page_title="Customers & Loyalty", page_icon=":busts_in_silhouette:", layout="wide")
st.title("Customers & Loyalty")

filters = st.session_state.get("global_filters", {})
df = get_order_data(filters)

if df.empty:
    st.warning("No data available.")
    st.stop()

# ---------------------------------------------------------------------------
# Loyalty comparison KPIs
# ---------------------------------------------------------------------------

st.subheader("Loyalty Program Performance")

loy = loyalty_comparison(df)
if not loy.empty:
    cols = st.columns(len(loy))
    for i, (_, row) in enumerate(loy.iterrows()):
        label = "Loyalty Members" if row["loyalty_status"] == "Yes" else "Non-Members"
        with cols[i]:
            st.markdown(f"**{label}**")
            st.metric("Revenue", f"${row['total_revenue']:,.0f}")
            st.metric("Orders", f"{row['total_orders']:,}")
            st.metric("AOV", f"${row['avg_order_value']:,.2f}")
            st.metric("Unique Customers", f"{row['unique_customers']:,}")

st.divider()

# ---------------------------------------------------------------------------
# New vs returning customers
# ---------------------------------------------------------------------------

st.subheader("New vs Returning Customers by Month")

cust_monthly = customers_by_month(df)
if not cust_monthly.empty:
    fig = px.bar(
        cust_monthly,
        x="month",
        y="customers",
        color="customer_type",
        barmode="stack",
        labels={"month": "Month", "customers": "Customers", "customer_type": "Type"},
        color_discrete_map={"New": "#636EFA", "Returning": "#00CC96"},
    )
    fig.update_layout(hovermode="x unified")
    st.plotly_chart(fig, use_container_width=True)

st.divider()

# ---------------------------------------------------------------------------
# Demographics
# ---------------------------------------------------------------------------

st.subheader("Customer Demographics")

demo = customer_demographics(df)
if not demo.empty:
    col_left, col_right = st.columns(2)

    with col_left:
        age_data = demo.groupby("age_group").agg(revenue=("revenue", "sum")).reset_index()
        fig_age = px.bar(
            age_data,
            x="age_group",
            y="revenue",
            labels={"age_group": "Age Group", "revenue": "Revenue ($)"},
            color="age_group",
        )
        fig_age.update_layout(showlegend=False, yaxis_tickprefix="$", yaxis_tickformat=",")
        st.plotly_chart(fig_age, use_container_width=True)

    with col_right:
        gender_data = demo.groupby("gender").agg(revenue=("revenue", "sum")).reset_index()
        gender_data = gender_data[gender_data["gender"].notna()]
        fig_gen = px.pie(
            gender_data,
            names="gender",
            values="revenue",
            hole=0.4,
        )
        fig_gen.update_traces(textposition="inside", textinfo="label+percent")
        st.plotly_chart(fig_gen, use_container_width=True)

st.divider()

# ---------------------------------------------------------------------------
# Top customers table
# ---------------------------------------------------------------------------

st.subheader("Top 20 Customers by Revenue")

top = top_customers(df, 20)
if not top.empty:
    display = top.copy()
    display["total_revenue"] = display["total_revenue"].apply(lambda v: f"${v:,.0f}")
    display["avg_order_value"] = display["avg_order_value"].apply(lambda v: f"${v:,.2f}")
    display.columns = ["Customer ID", "Loyalty", "Total Revenue", "Orders", "AOV"]
    st.dataframe(display, use_container_width=True, hide_index=True)

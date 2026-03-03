"""Operations — Order status, cancellations, shipping usage."""

import sys
from pathlib import Path

import streamlit as st
import plotly.express as px
import plotly.graph_objects as go

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from queries import (
    get_order_data,
    order_status_breakdown,
    cancellation_rate_over_time,
    shipping_usage_over_time,
)

# ---------------------------------------------------------------------------
# Page setup
# ---------------------------------------------------------------------------

st.set_page_config(page_title="Operations", page_icon=":gear:", layout="wide")
st.title("Operations")

filters = st.session_state.get("global_filters", {})
df = get_order_data(filters)

if df.empty:
    st.warning("No data available.")
    st.stop()

# ---------------------------------------------------------------------------
# KPI row
# ---------------------------------------------------------------------------

total_orders = len(df)
completed = (df["order_status"] == "Completed").sum()
cancelled = (df["order_status"] == "Cancelled").sum()
avg_units = df["quantity"].mean() if "quantity" in df.columns else 0

c1, c2, c3, c4 = st.columns(4)
c1.metric("Total Orders", f"{total_orders:,}")
c2.metric("Completed", f"{completed:,}")
c3.metric("Cancelled", f"{cancelled:,}")
c4.metric("Avg Units / Order", f"{avg_units:.2f}")

st.divider()

# ---------------------------------------------------------------------------
# Order status breakdown
# ---------------------------------------------------------------------------

col_left, col_right = st.columns(2)

with col_left:
    st.subheader("Order Status Breakdown")
    status_df = order_status_breakdown(df)
    if not status_df.empty:
        fig = px.pie(
            status_df,
            names="order_status",
            values="orders",
            hole=0.45,
            color="order_status",
            color_discrete_map={"Completed": "#00CC96", "Cancelled": "#EF553B"},
        )
        fig.update_traces(textposition="inside", textinfo="label+percent+value")
        st.plotly_chart(fig, use_container_width=True)

# ---------------------------------------------------------------------------
# Cancellation rate over time
# ---------------------------------------------------------------------------

with col_right:
    st.subheader("Cancellation Rate Over Time")
    cancel_df = cancellation_rate_over_time(df)
    if not cancel_df.empty:
        fig2 = go.Figure()
        fig2.add_trace(go.Scatter(
            x=cancel_df["month"],
            y=cancel_df["cancellation_rate"],
            mode="lines+markers",
            fill="tozeroy",
            marker_color="#EF553B",
        ))
        fig2.update_layout(
            yaxis=dict(title="Cancellation Rate (%)", ticksuffix="%"),
            xaxis=dict(title="Month"),
            hovermode="x unified",
        )
        st.plotly_chart(fig2, use_container_width=True)

st.divider()

# ---------------------------------------------------------------------------
# Shipping usage over time
# ---------------------------------------------------------------------------

st.subheader("Shipping Type Usage Over Time")

ship_df = shipping_usage_over_time(df)
if not ship_df.empty:
    fig3 = px.area(
        ship_df,
        x="month",
        y="orders",
        color="shipping_type",
        labels={"month": "Month", "orders": "Orders", "shipping_type": "Shipping"},
    )
    fig3.update_layout(hovermode="x unified")
    st.plotly_chart(fig3, use_container_width=True)

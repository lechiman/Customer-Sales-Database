"""Revenue Trends — MoM growth, revenue by payment and shipping."""

import sys
from pathlib import Path

import streamlit as st
import plotly.express as px
import plotly.graph_objects as go

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from queries import get_order_data, monthly_revenue, revenue_by_payment, revenue_by_shipping

# ---------------------------------------------------------------------------
# Page setup
# ---------------------------------------------------------------------------

st.set_page_config(page_title="Revenue Trends", page_icon=":chart_with_upwards_trend:", layout="wide")
st.title("Revenue Trends")

filters = st.session_state.get("global_filters", {})
df = get_order_data(filters)

if df.empty:
    st.warning("No data available.")
    st.stop()

# ---------------------------------------------------------------------------
# Monthly revenue with MoM change
# ---------------------------------------------------------------------------

st.subheader("Monthly Revenue & Month-over-Month Change")

monthly = monthly_revenue(df)
if not monthly.empty:
    fig = go.Figure()

    fig.add_trace(go.Bar(
        x=monthly["month"],
        y=monthly["revenue"],
        name="Revenue",
        marker_color="#636EFA",
        yaxis="y",
    ))

    fig.add_trace(go.Scatter(
        x=monthly["month"],
        y=monthly["mom_change_pct"],
        name="MoM Change %",
        mode="lines+markers",
        marker_color="#EF553B",
        yaxis="y2",
    ))

    fig.update_layout(
        yaxis=dict(title="Revenue ($)", tickprefix="$", tickformat=",", side="left"),
        yaxis2=dict(title="MoM Change (%)", ticksuffix="%", overlaying="y", side="right"),
        legend=dict(orientation="h", yanchor="bottom", y=1.02),
        hovermode="x unified",
    )
    st.plotly_chart(fig, use_container_width=True)

    # 3-month moving average
    st.subheader("3-Month Moving Average")
    monthly["ma_3"] = monthly["revenue"].rolling(3, min_periods=1).mean()
    fig_ma = px.line(
        monthly,
        x="month",
        y=["revenue", "ma_3"],
        labels={"value": "Revenue ($)", "month": "Month", "variable": "Series"},
    )
    fig_ma.update_layout(yaxis_tickprefix="$", yaxis_tickformat=",", hovermode="x unified")
    # Rename legend entries
    fig_ma.data[0].name = "Monthly Revenue"
    fig_ma.data[1].name = "3-Month Avg"
    st.plotly_chart(fig_ma, use_container_width=True)

st.divider()

# ---------------------------------------------------------------------------
# Revenue by payment method + shipping type
# ---------------------------------------------------------------------------

col_left, col_right = st.columns(2)

with col_left:
    st.subheader("Revenue by Payment Method")
    pay = revenue_by_payment(df)
    if not pay.empty:
        fig_pay = px.pie(
            pay,
            names="payment_method",
            values="revenue",
            hole=0.4,
        )
        fig_pay.update_traces(textposition="inside", textinfo="label+percent")
        st.plotly_chart(fig_pay, use_container_width=True)

with col_right:
    st.subheader("Revenue by Shipping Type")
    ship = revenue_by_shipping(df)
    if not ship.empty:
        fig_ship = px.pie(
            ship,
            names="shipping_type",
            values="revenue",
            hole=0.4,
        )
        fig_ship.update_traces(textposition="inside", textinfo="label+percent")
        st.plotly_chart(fig_ship, use_container_width=True)

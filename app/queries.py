"""
SQL queries and CSV-equivalent data accessors for the dashboard.

Each function returns a pandas DataFrame. When a database is connected,
queries run against the normalized schema. When running in CSV-fallback
mode, equivalent pandas operations produce the same result shape.

All SQL uses parameterized queries via SQLAlchemy text() binding.
"""

import pandas as pd
import streamlit as st

from db import query, load_csv_data, get_mode

# ===================================================================
# Helpers
# ===================================================================

def _apply_global_filters(df: pd.DataFrame, filters: dict) -> pd.DataFrame:
    """Apply sidebar filters to a raw CSV DataFrame."""
    if filters.get("date_range"):
        start, end = filters["date_range"]
        df = df[(df["purchase_date"] >= pd.Timestamp(start)) &
                (df["purchase_date"] <= pd.Timestamp(end))]
    if filters.get("product_type") and filters["product_type"] != ["All"]:
        df = df[df["product_type"].isin(filters["product_type"])]
    if filters.get("loyalty") and filters["loyalty"] != "All":
        df = df[df["loyalty_member"] == filters["loyalty"]]
    if filters.get("shipping_type") and filters["shipping_type"] != ["All"]:
        df = df[df["shipping_type"].isin(filters["shipping_type"])]
    if filters.get("payment_method") and filters["payment_method"] != ["All"]:
        df = df[df["payment_method"].isin(filters["payment_method"])]
    return df


def _build_where_clauses(filters: dict) -> tuple[str, dict]:
    """Build SQL WHERE clause fragments from filters dict."""
    clauses = []
    params = {}

    if filters.get("date_range"):
        clauses.append("o.purchase_date BETWEEN :start_date AND :end_date")
        params["start_date"] = str(filters["date_range"][0])
        params["end_date"] = str(filters["date_range"][1])

    if filters.get("product_type") and filters["product_type"] != ["All"]:
        placeholders = ", ".join(f":pt_{i}" for i in range(len(filters["product_type"])))
        clauses.append(f"pc.category_name IN ({placeholders})")
        for i, pt in enumerate(filters["product_type"]):
            params[f"pt_{i}"] = pt

    if filters.get("loyalty") and filters["loyalty"] != "All":
        clauses.append("c.current_loyalty = :loyalty")
        params["loyalty"] = filters["loyalty"]

    if filters.get("shipping_type") and filters["shipping_type"] != ["All"]:
        placeholders = ", ".join(f":st_{i}" for i in range(len(filters["shipping_type"])))
        clauses.append(f"sm.shipping_type IN ({placeholders})")
        for i, st_val in enumerate(filters["shipping_type"]):
            params[f"st_{i}"] = st_val

    if filters.get("payment_method") and filters["payment_method"] != ["All"]:
        placeholders = ", ".join(f":pm_{i}" for i in range(len(filters["payment_method"])))
        clauses.append(f"pm.payment_type IN ({placeholders})")
        for i, pm_val in enumerate(filters["payment_method"]):
            params[f"pm_{i}"] = pm_val

    where = " AND ".join(clauses)
    if where:
        where = "WHERE " + where
    return where, params


# ===================================================================
# Base query: order-level data with all joins (DB mode)
# ===================================================================

_BASE_ORDER_SQL = """
SELECT
    o.order_id,
    o.customer_id,
    o.purchase_date,
    os.status_name          AS order_status,
    pm.payment_type         AS payment_method,
    sm.shipping_type        AS shipping_type,
    pc.category_name        AS product_type,
    p.sku,
    oi.quantity,
    oi.unit_price,
    oi.line_total,
    oi.rating,
    c.age,
    c.gender,
    c.current_loyalty       AS loyalty_member,
    COALESCE(addon_agg.addon_total, 0) AS addon_total
FROM orders o
JOIN customers c            ON o.customer_id  = c.customer_id
JOIN order_statuses os      ON o.status_id    = os.status_id
JOIN payment_methods pm     ON o.payment_id   = pm.payment_id
JOIN shipping_methods sm    ON o.shipping_id   = sm.shipping_id
JOIN order_items oi         ON o.order_id     = oi.order_id
JOIN products p             ON oi.product_id  = p.product_id
JOIN product_categories pc  ON p.category_id  = pc.category_id
LEFT JOIN (
    SELECT order_item_id, SUM(addon_price) AS addon_total
    FROM order_addons
    GROUP BY order_item_id
) addon_agg ON oi.order_item_id = addon_agg.order_item_id
"""


@st.cache_data(ttl=300, show_spinner="Loading data...")
def get_order_data(filters: dict | None = None) -> pd.DataFrame:
    """
    Return order-level data. This is the primary data source for all pages.
    Cached for 5 minutes.
    """
    filters = filters or {}

    if get_mode() == "db":
        where, params = _build_where_clauses(filters)
        sql = _BASE_ORDER_SQL + where + " ORDER BY o.purchase_date"
        df = query(sql, params)
        if "purchase_date" in df.columns:
            df["purchase_date"] = pd.to_datetime(df["purchase_date"])
        if "line_total" in df.columns:
            df["order_revenue"] = df["line_total"] + df["addon_total"]
        return df
    else:
        df = load_csv_data()
        if df.empty:
            return df
        df = _apply_global_filters(df, filters)
        return df


# ===================================================================
# KPI helpers (work on the DataFrame from get_order_data)
# ===================================================================

def calc_executive_kpis(df: pd.DataFrame) -> dict:
    """Calculate top-line KPI values from order data."""
    if df.empty:
        return {
            "total_revenue": 0,
            "total_orders": 0,
            "total_customers": 0,
            "aov": 0,
            "cancellation_rate": 0,
            "addon_attachment_rate": 0,
        }

    completed = df[df["order_status"] == "Completed"]
    revenue_col = "order_revenue" if "order_revenue" in df.columns else "total_price"

    total_revenue = completed[revenue_col].sum()
    total_orders = df["order_id"].nunique() if "order_id" in df.columns else len(df)
    completed_orders = completed["order_id"].nunique() if "order_id" in completed.columns else len(completed)
    total_customers = df["customer_id"].nunique()

    aov = total_revenue / completed_orders if completed_orders > 0 else 0
    cancellation_rate = (
        (total_orders - completed_orders) / total_orders * 100
        if total_orders > 0 else 0
    )

    addon_col = "addon_total"
    if addon_col in df.columns:
        orders_with_addons = (df[addon_col] > 0).sum()
        addon_rate = orders_with_addons / len(df) * 100 if len(df) > 0 else 0
    else:
        addon_rate = 0

    return {
        "total_revenue": total_revenue,
        "total_orders": total_orders,
        "total_customers": total_customers,
        "aov": aov,
        "cancellation_rate": cancellation_rate,
        "addon_attachment_rate": addon_rate,
    }


def monthly_revenue(df: pd.DataFrame) -> pd.DataFrame:
    """Aggregate revenue by month."""
    if df.empty:
        return pd.DataFrame(columns=["month", "revenue", "orders"])

    completed = df[df["order_status"] == "Completed"].copy()
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"

    completed["month"] = completed["purchase_date"].dt.to_period("M").dt.to_timestamp()
    agg = completed.groupby("month").agg(
        revenue=(revenue_col, "sum"),
        orders=("order_id" if "order_id" in completed.columns else "customer_id", "count"),
    ).reset_index()
    agg = agg.sort_values("month")

    # MoM change
    agg["mom_change_pct"] = agg["revenue"].pct_change() * 100

    return agg


def revenue_by_product(df: pd.DataFrame) -> pd.DataFrame:
    """Revenue breakdown by product category."""
    if df.empty:
        return pd.DataFrame()
    completed = df[df["order_status"] == "Completed"]
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"
    return (
        completed.groupby("product_type")
        .agg(revenue=(revenue_col, "sum"), orders=("product_type", "count"))
        .reset_index()
        .sort_values("revenue", ascending=False)
    )


def revenue_by_payment(df: pd.DataFrame) -> pd.DataFrame:
    """Revenue by payment method."""
    if df.empty:
        return pd.DataFrame()
    completed = df[df["order_status"] == "Completed"]
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"
    return (
        completed.groupby("payment_method")
        .agg(revenue=(revenue_col, "sum"), orders=("payment_method", "count"))
        .reset_index()
        .sort_values("revenue", ascending=False)
    )


def revenue_by_shipping(df: pd.DataFrame) -> pd.DataFrame:
    """Revenue by shipping type."""
    if df.empty:
        return pd.DataFrame()
    completed = df[df["order_status"] == "Completed"]
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"
    return (
        completed.groupby("shipping_type")
        .agg(revenue=(revenue_col, "sum"), orders=("shipping_type", "count"))
        .reset_index()
        .sort_values("revenue", ascending=False)
    )


def top_products(df: pd.DataFrame, n: int = 10) -> pd.DataFrame:
    """Top N products by revenue."""
    if df.empty:
        return pd.DataFrame()
    completed = df[df["order_status"] == "Completed"]
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"
    return (
        completed.groupby(["product_type", "sku"])
        .agg(
            revenue=(revenue_col, "sum"),
            units_sold=("quantity", "sum"),
            avg_rating=("rating", "mean"),
        )
        .reset_index()
        .sort_values("revenue", ascending=False)
        .head(n)
    )


def loyalty_comparison(df: pd.DataFrame) -> pd.DataFrame:
    """Loyalty vs non-loyalty metrics."""
    if df.empty:
        return pd.DataFrame()
    completed = df[df["order_status"] == "Completed"]
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"
    loy_col = "loyalty_member" if "loyalty_member" in completed.columns else "current_loyalty"
    return (
        completed.groupby(loy_col)
        .agg(
            total_revenue=(revenue_col, "sum"),
            total_orders=(loy_col, "count"),
            avg_order_value=(revenue_col, "mean"),
            unique_customers=("customer_id", "nunique"),
        )
        .reset_index()
        .rename(columns={loy_col: "loyalty_status"})
    )


def customers_by_month(df: pd.DataFrame) -> pd.DataFrame:
    """New vs returning customers by month."""
    if df.empty:
        return pd.DataFrame()

    df_sorted = df.sort_values("purchase_date").copy()
    first_purchase = df_sorted.groupby("customer_id")["purchase_date"].min().reset_index()
    first_purchase.columns = ["customer_id", "first_purchase"]
    first_purchase["first_month"] = first_purchase["first_purchase"].dt.to_period("M").dt.to_timestamp()

    df_sorted["month"] = df_sorted["purchase_date"].dt.to_period("M").dt.to_timestamp()
    merged = df_sorted.merge(first_purchase[["customer_id", "first_month"]], on="customer_id")
    merged["customer_type"] = merged.apply(
        lambda r: "New" if r["month"] == r["first_month"] else "Returning", axis=1
    )

    return (
        merged.groupby(["month", "customer_type"])
        .agg(customers=("customer_id", "nunique"))
        .reset_index()
        .sort_values("month")
    )


def customer_demographics(df: pd.DataFrame) -> pd.DataFrame:
    """Customer segmentation by age group and gender."""
    if df.empty:
        return pd.DataFrame()

    completed = df[df["order_status"] == "Completed"].copy()
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"

    def age_group(age):
        if pd.isna(age):
            return "Unknown"
        age = int(age)
        if age < 25:
            return "18-24"
        if age < 35:
            return "25-34"
        if age < 45:
            return "35-44"
        if age < 55:
            return "45-54"
        return "55+"

    completed["age_group"] = completed["age"].apply(age_group)
    return (
        completed.groupby(["age_group", "gender"])
        .agg(
            revenue=(revenue_col, "sum"),
            customers=("customer_id", "nunique"),
            avg_order_value=(revenue_col, "mean"),
        )
        .reset_index()
        .sort_values("revenue", ascending=False)
    )


def top_customers(df: pd.DataFrame, n: int = 20) -> pd.DataFrame:
    """Top customers by total revenue."""
    if df.empty:
        return pd.DataFrame()
    completed = df[df["order_status"] == "Completed"]
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"
    loy_col = "loyalty_member" if "loyalty_member" in completed.columns else "current_loyalty"
    return (
        completed.groupby(["customer_id", loy_col])
        .agg(
            total_revenue=(revenue_col, "sum"),
            total_orders=("customer_id", "count"),
            avg_order_value=(revenue_col, "mean"),
        )
        .reset_index()
        .rename(columns={loy_col: "loyalty_status"})
        .sort_values("total_revenue", ascending=False)
        .head(n)
    )


def order_status_breakdown(df: pd.DataFrame) -> pd.DataFrame:
    """Order counts by status."""
    if df.empty:
        return pd.DataFrame()
    return (
        df.groupby("order_status")
        .agg(orders=("order_status", "count"))
        .reset_index()
    )


def cancellation_rate_over_time(df: pd.DataFrame) -> pd.DataFrame:
    """Monthly cancellation rate."""
    if df.empty:
        return pd.DataFrame()
    df_copy = df.copy()
    df_copy["month"] = df_copy["purchase_date"].dt.to_period("M").dt.to_timestamp()
    monthly = df_copy.groupby("month").agg(
        total=("order_status", "count"),
        cancelled=("order_status", lambda x: (x == "Cancelled").sum()),
    ).reset_index()
    monthly["cancellation_rate"] = monthly["cancelled"] / monthly["total"] * 100
    return monthly.sort_values("month")


def shipping_usage_over_time(df: pd.DataFrame) -> pd.DataFrame:
    """Shipping type counts by month."""
    if df.empty:
        return pd.DataFrame()
    df_copy = df.copy()
    df_copy["month"] = df_copy["purchase_date"].dt.to_period("M").dt.to_timestamp()
    return (
        df_copy.groupby(["month", "shipping_type"])
        .agg(orders=("shipping_type", "count"))
        .reset_index()
        .sort_values("month")
    )


def product_trend(df: pd.DataFrame, product_type: str) -> pd.DataFrame:
    """Monthly revenue trend for a specific product category."""
    if df.empty:
        return pd.DataFrame()
    completed = df[(df["order_status"] == "Completed") & (df["product_type"] == product_type)].copy()
    revenue_col = "order_revenue" if "order_revenue" in completed.columns else "total_price"
    completed["month"] = completed["purchase_date"].dt.to_period("M").dt.to_timestamp()
    return (
        completed.groupby("month")
        .agg(revenue=(revenue_col, "sum"), units=("quantity", "sum"))
        .reset_index()
        .sort_values("month")
    )


def rating_distribution(df: pd.DataFrame) -> pd.DataFrame:
    """Distribution of product ratings."""
    if df.empty:
        return pd.DataFrame()
    rated = df[df["rating"].notna()].copy()
    rated["rating"] = rated["rating"].astype(int)
    return (
        rated.groupby("rating")
        .agg(count=("rating", "count"))
        .reset_index()
        .sort_values("rating")
    )

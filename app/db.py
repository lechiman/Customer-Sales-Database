"""
Database connection layer for the Electronic Sales Dashboard.

Supports:
- MySQL / PostgreSQL via DATABASE_URL environment variable
- SQLite for local demo (sqlite:///path/to/file.db)
- CSV fallback when no database is available

Uses SQLAlchemy for connection management and Streamlit caching
to avoid reconnecting on every rerun.
"""

import os
import hashlib
from pathlib import Path

import pandas as pd
import streamlit as st
from dotenv import load_dotenv

load_dotenv()

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

CSV_PATH = Path(__file__).resolve().parent.parent / "Electronic_sales_Sep2023-Sep2024.csv"
DATABASE_URL = os.getenv("DATABASE_URL", "")

# ---------------------------------------------------------------------------
# Engine creation (cached once per app lifetime)
# ---------------------------------------------------------------------------

@st.cache_resource
def get_engine():
    """Create and cache a SQLAlchemy engine from DATABASE_URL."""
    if not DATABASE_URL:
        return None
    try:
        from sqlalchemy import create_engine
        engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_size=5)
        # Quick connection test
        with engine.connect() as conn:
            conn.execute(__import__("sqlalchemy").text("SELECT 1"))
        return engine
    except Exception as e:
        st.warning(f"Could not connect to database: {e}")
        return None


# ---------------------------------------------------------------------------
# Query runner
# ---------------------------------------------------------------------------

def _params_hash(params: dict | None) -> str:
    """Deterministic hash for cache keying."""
    if not params:
        return ""
    return hashlib.md5(str(sorted(params.items())).encode()).hexdigest()


@st.cache_data(ttl=300, show_spinner=False)
def run_query(sql: str, params: dict | None = None, _params_key: str = "") -> pd.DataFrame:
    """
    Execute SQL against the database and return a DataFrame.

    Parameters are passed safely via SQLAlchemy's text() binding —
    never string-formatted into the query.
    """
    engine = get_engine()
    if engine is None:
        return pd.DataFrame()

    from sqlalchemy import text
    with engine.connect() as conn:
        result = conn.execute(text(sql), params or {})
        df = pd.DataFrame(result.fetchall(), columns=result.keys())
    return df


def query(sql: str, params: dict | None = None) -> pd.DataFrame:
    """Public wrapper that handles cache keying."""
    return run_query(sql, params, _params_key=_params_hash(params))


# ---------------------------------------------------------------------------
# CSV fallback loader
# ---------------------------------------------------------------------------

@st.cache_data(show_spinner=False)
def load_csv_data() -> pd.DataFrame:
    """
    Load the raw CSV as a fallback when no database is configured.
    Applies basic cleaning to mimic the normalized schema output.
    """
    if not CSV_PATH.exists():
        return pd.DataFrame()

    df = pd.read_csv(CSV_PATH)

    # Standardize column names to snake_case
    df.columns = [c.strip().lower().replace(" ", "_").replace("-", "_") for c in df.columns]

    # Clean Payment Method inconsistency
    df["payment_method"] = df["payment_method"].replace("Paypal", "PayPal")

    # Clean Gender #N/A
    df["gender"] = df["gender"].replace("#N/A", None)

    # Parse dates
    df["purchase_date"] = pd.to_datetime(df["purchase_date"], errors="coerce")

    # Rename for consistency with normalized schema
    df = df.rename(columns={
        "add_ons_purchased": "addons_purchased",
        "add_on_total": "addon_total",
    })

    # Derived fields
    df["order_revenue"] = df["total_price"] + df["addon_total"].fillna(0)

    # Add order_id (row index) for CSV mode since there's no DB surrogate key
    df["order_id"] = range(1, len(df) + 1)

    return df


# ---------------------------------------------------------------------------
# Unified data access
# ---------------------------------------------------------------------------

def is_db_available() -> bool:
    """Check whether a live database connection exists."""
    return get_engine() is not None


def get_mode() -> str:
    """Return 'db' or 'csv' depending on what is available."""
    return "db" if is_db_available() else "csv"

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import numpy as np
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

# Configure the page
st.set_page_config(
    page_title="Electronic Sales Analytics Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
<style>
    .main > div {
        padding-top: 2rem;
    }
    .stMetric > div > div > div > div {
        font-size: 1rem;
    }
    .css-1d391kg {
        padding-top: 1rem;
    }
</style>
""", unsafe_allow_html=True)

@st.cache_data
def load_data():
    """Load and preprocess the electronic sales data"""
    try:
        # Load the CSV data
        df = pd.read_csv('Electronic_sales_Sep2023-Sep2024.csv')
        
        # Clean column names - handle spaces, hyphens, and case
        df.columns = df.columns.str.replace(' ', '_').str.replace('-', '_').str.lower()
        
        # Convert date column
        df['purchase_date'] = pd.to_datetime(df['purchase_date'])
        
        # Create additional date features
        df['year'] = df['purchase_date'].dt.year
        df['month'] = df['purchase_date'].dt.month
        df['month_name'] = df['purchase_date'].dt.strftime('%B')
        df['day_name'] = df['purchase_date'].dt.strftime('%A')
        df['quarter'] = df['purchase_date'].dt.quarter
        
        # Create age groups
        df['age_group'] = pd.cut(df['age'], 
                               bins=[0, 25, 35, 45, 55, 100], 
                               labels=['18-24', '25-34', '35-44', '45-54', '55+'],
                               include_lowest=True)
        
        # Create customer value segments based on total spending
        customer_spending = df.groupby('customer_id')['total_price'].sum().reset_index()
        customer_spending['value_segment'] = pd.cut(customer_spending['total_price'],
                                                   bins=[0, 500, 2000, 5000, float('inf')],
                                                   labels=['Low (<$500)', 'Regular ($500-2K)', 'Medium ($2K-5K)', 'High ($5K+)'],
                                                   include_lowest=True)
        
        # Merge back with main dataframe
        df = df.merge(customer_spending[['customer_id', 'value_segment']], on='customer_id', how='left')
        
        # Create season column
        df['season'] = df['month'].map({12: 'Winter', 1: 'Winter', 2: 'Winter',
                                       3: 'Spring', 4: 'Spring', 5: 'Spring',
                                       6: 'Summer', 7: 'Summer', 8: 'Summer',
                                       9: 'Fall', 10: 'Fall', 11: 'Fall'})
        
        return df
    except Exception as e:
        st.error(f"Error loading data: {str(e)}")
        return None

def main():
    st.title("📊 Electronic Sales Analytics Dashboard")
    st.markdown("---")
    
    # Load data
    df = load_data()
    
    if df is None:
        st.stop()
    
    # Sidebar filters
    st.sidebar.header("🎛️ Dashboard Filters")
    
    # Date range filter
    date_range = st.sidebar.date_input(
        "Select Date Range",
        value=(df['purchase_date'].min(), df['purchase_date'].max()),
        min_value=df['purchase_date'].min(),
        max_value=df['purchase_date'].max()
    )
    
    # Other filters
    selected_status = st.sidebar.multiselect(
        "Order Status", 
        options=df['order_status'].unique(),
        default=df['order_status'].unique()
    )
    
    selected_products = st.sidebar.multiselect(
        "Product Types",
        options=df['product_type'].unique(),
        default=df['product_type'].unique()
    )
    
    selected_payment = st.sidebar.multiselect(
        "Payment Methods",
        options=df['payment_method'].unique(),
        default=df['payment_method'].unique()
    )
    
    # Apply filters
    if len(date_range) == 2:
        mask = (df['purchase_date'] >= pd.Timestamp(date_range[0])) & \
               (df['purchase_date'] <= pd.Timestamp(date_range[1]))
        filtered_df = df[mask]
    else:
        filtered_df = df.copy()
    
    filtered_df = filtered_df[
        (filtered_df['order_status'].isin(selected_status)) &
        (filtered_df['product_type'].isin(selected_products)) &
        (filtered_df['payment_method'].isin(selected_payment))
    ]
    
    # Key Metrics
    st.header("📈 Key Performance Metrics")
    
    col1, col2, col3, col4, col5 = st.columns(5)
    
    with col1:
        total_revenue = filtered_df[filtered_df['order_status'] == 'Completed']['total_price'].sum()
        st.metric("Total Revenue", f"${total_revenue:,.2f}")
    
    with col2:
        total_orders = len(filtered_df)
        st.metric("Total Orders", f"{total_orders:,}")
    
    with col3:
        unique_customers = filtered_df['customer_id'].nunique()
        st.metric("Unique Customers", f"{unique_customers:,}")
    
    with col4:
        avg_order_value = filtered_df[filtered_df['order_status'] == 'Completed']['total_price'].mean()
        st.metric("Avg Order Value", f"${avg_order_value:.2f}")
    
    with col5:
        completion_rate = (filtered_df['order_status'] == 'Completed').mean() * 100
        st.metric("Completion Rate", f"{completion_rate:.1f}%")
    
    st.markdown("---")
    
    # Main dashboard tabs
    tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
        "📊 Sales Overview", 
        "👥 Customer Analytics", 
        "📱 Product Performance", 
        "📅 Time Series Analysis",
        "💰 Revenue Analysis",
        "🧮 Custom Calculations"
    ])
    
    with tab1:
        st.header("Sales Overview")
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Order status distribution
            status_counts = filtered_df['order_status'].value_counts()
            fig_status = px.pie(
                values=status_counts.values,
                names=status_counts.index,
                title="Order Status Distribution",
                color_discrete_map={'Completed': '#2E8B57', 'Cancelled': '#DC143C'}
            )
            st.plotly_chart(fig_status, use_container_width=True)
        
        with col2:
            # Payment method distribution
            payment_counts = filtered_df['payment_method'].value_counts()
            fig_payment = px.bar(
                x=payment_counts.values,
                y=payment_counts.index,
                orientation='h',
                title="Payment Method Distribution",
                labels={'x': 'Number of Orders', 'y': 'Payment Method'}
            )
            fig_payment.update_layout(yaxis={'categoryorder': 'total ascending'})
            st.plotly_chart(fig_payment, use_container_width=True)
        
        # Product type performance
        product_summary = filtered_df.groupby('product_type').agg({
            'total_price': ['sum', 'mean', 'count'],
            'rating': 'mean'
        }).round(2)
        
        product_summary.columns = ['Total Revenue', 'Avg Order Value', 'Order Count', 'Avg Rating']
        product_summary = product_summary.sort_values('Total Revenue', ascending=False)
        
        st.subheader("Product Type Performance")
        st.dataframe(product_summary, use_container_width=True)
    
    with tab2:
        st.header("Customer Analytics")
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Customer age distribution
            age_dist = filtered_df['age_group'].value_counts()
            fig_age = px.bar(
                x=age_dist.index,
                y=age_dist.values,
                title="Customer Age Distribution",
                labels={'x': 'Age Group', 'y': 'Number of Customers'}
            )
            st.plotly_chart(fig_age, use_container_width=True)
        
        with col2:
            # Gender distribution
            gender_dist = filtered_df['gender'].value_counts()
            fig_gender = px.pie(
                values=gender_dist.values,
                names=gender_dist.index,
                title="Gender Distribution"
            )
            st.plotly_chart(fig_gender, use_container_width=True)
        
        col3, col4 = st.columns(2)
        
        with col3:
            # Loyalty member analysis
            loyalty_analysis = filtered_df.groupby('loyalty_member').agg({
                'total_price': 'mean',
                'add_on_total': 'mean',
                'rating': 'mean'
            }).round(2)
            
            st.subheader("Loyalty Member Analysis")
            st.dataframe(loyalty_analysis, use_container_width=True)
        
        with col4:
            # Customer value segments
            value_segments = filtered_df['value_segment'].value_counts()
            fig_segments = px.bar(
                x=value_segments.values,
                y=value_segments.index,
                orientation='h',
                title="Customer Value Segments"
            )
            st.plotly_chart(fig_segments, use_container_width=True)
        
        # Top customers table
        st.subheader("Top 10 Customers by Revenue")
        top_customers = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('customer_id').agg({
            'total_price': ['sum', 'mean', 'count'],
            'rating': 'mean'
        }).round(2)
        
        top_customers.columns = ['Total Spent', 'Avg Order Value', 'Order Count', 'Avg Rating']
        top_customers = top_customers.sort_values('Total Spent', ascending=False).head(10)
        st.dataframe(top_customers, use_container_width=True)
    
    with tab3:
        st.header("Product Performance")
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Best selling products by revenue
            product_revenue = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('product_type')['total_price'].sum().sort_values(ascending=False)
            fig_product_revenue = px.bar(
                x=product_revenue.values,
                y=product_revenue.index,
                orientation='h',
                title="Revenue by Product Type",
                labels={'x': 'Total Revenue ($)', 'y': 'Product Type'}
            )
            st.plotly_chart(fig_product_revenue, use_container_width=True)
        
        with col2:
            # Product ratings distribution
            rating_dist = filtered_df.dropna(subset=['rating'])['rating'].value_counts().sort_index()
            fig_rating = px.bar(
                x=rating_dist.index,
                y=rating_dist.values,
                title="Product Ratings Distribution",
                labels={'x': 'Rating', 'y': 'Number of Reviews'}
            )
            st.plotly_chart(fig_rating, use_container_width=True)
        
        # SKU performance table
        st.subheader("Top 15 SKUs by Performance")
        sku_performance = filtered_df[filtered_df['order_status'] == 'Completed'].groupby(['sku', 'product_type']).agg({
            'total_price': ['sum', 'mean', 'count'],
            'rating': 'mean',
            'quantity': 'sum'
        }).round(2)
        
        sku_performance.columns = ['Total Revenue', 'Avg Order Value', 'Order Count', 'Avg Rating', 'Units Sold']
        sku_performance = sku_performance.sort_values('Total Revenue', ascending=False).head(15)
        st.dataframe(sku_performance, use_container_width=True)
        
        # Add-on analysis
        st.subheader("Add-on Performance Analysis")
        addon_analysis = filtered_df.groupby('product_type').agg({
            'add_on_total': ['mean', lambda x: (x > 0).mean() * 100]
        }).round(2)
        
        addon_analysis.columns = ['Avg Add-on Value', 'Add-on Attachment Rate (%)']
        st.dataframe(addon_analysis, use_container_width=True)
    
    with tab4:
        st.header("Time Series Analysis")
        
        # Monthly sales trend
        monthly_sales = filtered_df[filtered_df['order_status'] == 'Completed'].groupby(
            filtered_df['purchase_date'].dt.to_period('M')
        )['total_price'].sum().reset_index()
        monthly_sales['purchase_date'] = monthly_sales['purchase_date'].dt.to_timestamp()
        
        fig_monthly = px.line(
            monthly_sales,
            x='purchase_date',
            y='total_price',
            title='Monthly Revenue Trend',
            labels={'purchase_date': 'Month', 'total_price': 'Revenue ($)'}
        )
        st.plotly_chart(fig_monthly, use_container_width=True)
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Seasonal analysis
            seasonal_sales = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('season')['total_price'].sum()
            fig_seasonal = px.bar(
                x=seasonal_sales.index,
                y=seasonal_sales.values,
                title="Revenue by Season",
                labels={'x': 'Season', 'y': 'Total Revenue ($)'}
            )
            st.plotly_chart(fig_seasonal, use_container_width=True)
        
        with col2:
            # Day of week analysis
            dow_sales = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('day_name')['total_price'].mean()
            # Reorder days of week
            day_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            dow_sales = dow_sales.reindex([day for day in day_order if day in dow_sales.index])
            
            fig_dow = px.bar(
                x=dow_sales.index,
                y=dow_sales.values,
                title="Average Order Value by Day of Week",
                labels={'x': 'Day of Week', 'y': 'Average Order Value ($)'}
            )
            st.plotly_chart(fig_dow, use_container_width=True)
        
        # Daily sales pattern
        daily_sales = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('purchase_date')['total_price'].sum()
        
        fig_daily = px.line(
            x=daily_sales.index,
            y=daily_sales.values,
            title='Daily Revenue Pattern',
            labels={'x': 'Date', 'y': 'Daily Revenue ($)'}
        )
        st.plotly_chart(fig_daily, use_container_width=True)
    
    with tab5:
        st.header("Revenue Analysis")
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Revenue by shipping type
            shipping_revenue = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('shipping_type').agg({
                'total_price': ['sum', 'mean', 'count']
            }).round(2)
            shipping_revenue.columns = ['Total Revenue', 'Avg Order Value', 'Order Count']
            
            st.subheader("Revenue by Shipping Type")
            st.dataframe(shipping_revenue, use_container_width=True)
        
        with col2:
            # Revenue contribution by customer segment
            segment_revenue = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('value_segment')['total_price'].sum()
            fig_segment_revenue = px.pie(
                values=segment_revenue.values,
                names=segment_revenue.index,
                title="Revenue Contribution by Customer Segment"
            )
            st.plotly_chart(fig_segment_revenue, use_container_width=True)
        
        # Quantity vs Price analysis
        st.subheader("Quantity vs Price Analysis")
        
        # Create scatter plot
        completed_orders = filtered_df[filtered_df['order_status'] == 'Completed']
        fig_scatter = px.scatter(
            completed_orders,
            x='quantity',
            y='total_price',
            color='product_type',
            size='rating',
            hover_data=['customer_id', 'sku'],
            title='Order Quantity vs Total Price (Size = Rating)'
        )
        st.plotly_chart(fig_scatter, use_container_width=True)
        
        # Revenue heatmap by month and product
        pivot_data = filtered_df[filtered_df['order_status'] == 'Completed'].pivot_table(
            values='total_price',
            index='product_type',
            columns='month_name',
            aggfunc='sum',
            fill_value=0
        )
        
        # Reorder months
        month_order = ['September', 'October', 'November', 'December', 'January', 'February', 
                      'March', 'April', 'May', 'June', 'July', 'August']
        pivot_data = pivot_data.reindex(columns=[m for m in month_order if m in pivot_data.columns])
        
        fig_heatmap = px.imshow(
            pivot_data.values,
            labels=dict(x="Month", y="Product Type", color="Revenue"),
            x=pivot_data.columns,
            y=pivot_data.index,
            title="Revenue Heatmap: Product Type vs Month"
        )
        st.plotly_chart(fig_heatmap, use_container_width=True)
    
    with tab6:
        st.header("Custom Calculations")
        
        st.subheader("🧮 Interactive Calculator")
        
        # Custom calculation options
        calc_type = st.selectbox(
            "Select Calculation Type",
            ["Customer Lifetime Value", "Product Profitability", "Conversion Rates", "Seasonal Multipliers"]
        )
        
        if calc_type == "Customer Lifetime Value":
            st.write("**Calculate Customer Lifetime Value (CLV)**")
            
            # CLV calculation
            customer_metrics = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('customer_id').agg({
                'total_price': ['sum', 'mean', 'count'],
                'purchase_date': ['min', 'max']
            })
            
            customer_metrics.columns = ['total_spent', 'avg_order_value', 'order_count', 'first_purchase', 'last_purchase']
            customer_metrics['customer_lifespan_days'] = (customer_metrics['last_purchase'] - customer_metrics['first_purchase']).dt.days
            customer_metrics['customer_lifespan_days'] = customer_metrics['customer_lifespan_days'].fillna(0)
            
            # Calculate CLV metrics
            avg_order_value = customer_metrics['avg_order_value'].mean()
            avg_purchase_frequency = customer_metrics['order_count'].mean()
            avg_customer_lifespan = customer_metrics['customer_lifespan_days'].mean() / 365  # in years
            
            clv = avg_order_value * avg_purchase_frequency * avg_customer_lifespan
            
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Average Order Value", f"${avg_order_value:.2f}")
            with col2:
                st.metric("Avg Purchase Frequency", f"{avg_purchase_frequency:.2f}")
            with col3:
                st.metric("Avg Customer Lifespan", f"{avg_customer_lifespan:.2f} years")
            with col4:
                st.metric("Estimated CLV", f"${clv:.2f}")
            
            # CLV distribution
            fig_clv = px.histogram(
                customer_metrics,
                x='total_spent',
                nbins=30,
                title='Customer Lifetime Value Distribution'
            )
            st.plotly_chart(fig_clv, use_container_width=True)
        
        elif calc_type == "Product Profitability":
            st.write("**Product Profitability Analysis**")
            
            # Assume cost percentage for calculation
            cost_percentage = st.slider("Estimated Cost of Goods Sold (%)", 40, 80, 60) / 100
            
            product_profit = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('product_type').agg({
                'total_price': 'sum',
                'quantity': 'sum'
            })
            
            product_profit['estimated_cost'] = product_profit['total_price'] * cost_percentage
            product_profit['gross_profit'] = product_profit['total_price'] - product_profit['estimated_cost']
            product_profit['profit_margin'] = (product_profit['gross_profit'] / product_profit['total_price'] * 100).round(2)
            
            st.dataframe(product_profit, use_container_width=True)
        
        elif calc_type == "Conversion Rates":
            st.write("**Conversion Rate Analysis**")
            
            conversion_metrics = filtered_df.groupby('product_type').agg({
                'order_status': [lambda x: (x == 'Completed').sum(), 'count']
            })
            
            conversion_metrics.columns = ['completed_orders', 'total_orders']
            conversion_metrics['conversion_rate'] = (conversion_metrics['completed_orders'] / conversion_metrics['total_orders'] * 100).round(2)
            
            fig_conversion = px.bar(
                x=conversion_metrics.index,
                y=conversion_metrics['conversion_rate'],
                title='Conversion Rate by Product Type (%)',
                labels={'x': 'Product Type', 'y': 'Conversion Rate (%)'}
            )
            st.plotly_chart(fig_conversion, use_container_width=True)
            
            st.dataframe(conversion_metrics, use_container_width=True)
        
        elif calc_type == "Seasonal Multipliers":
            st.write("**Seasonal Performance Multipliers**")
            
            # Calculate seasonal multipliers
            overall_avg = filtered_df[filtered_df['order_status'] == 'Completed']['total_price'].mean()
            seasonal_avg = filtered_df[filtered_df['order_status'] == 'Completed'].groupby('season')['total_price'].mean()
            seasonal_multipliers = (seasonal_avg / overall_avg).round(2)
            
            fig_multipliers = px.bar(
                x=seasonal_multipliers.index,
                y=seasonal_multipliers.values,
                title='Seasonal Performance Multipliers (1.0 = Average)',
                labels={'x': 'Season', 'y': 'Multiplier'}
            )
            fig_multipliers.add_hline(y=1.0, line_dash="dash", line_color="red", annotation_text="Average")
            st.plotly_chart(fig_multipliers, use_container_width=True)
            
            st.write("**Seasonal Multipliers Table:**")
            multiplier_df = pd.DataFrame({
                'Season': seasonal_multipliers.index,
                'Multiplier': seasonal_multipliers.values,
                'Performance': ['Above Average' if x > 1.0 else 'Below Average' for x in seasonal_multipliers.values]
            })
            st.dataframe(multiplier_df, use_container_width=True)
        
        # Export data section
        st.markdown("---")
        st.subheader("📤 Export Filtered Data")
        
        if st.button("Export Current View to CSV"):
            csv = filtered_df.to_csv(index=False)
            st.download_button(
                label="Download CSV file",
                data=csv,
                file_name=f"electronic_sales_filtered_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                mime="text/csv"
            )
    
    # Footer
    st.markdown("---")
    st.markdown(
        """
        <div style='text-align: center; color: #666666; padding: 20px;'>
            Electronic Sales Analytics Dashboard | Data Period: Sep 2023 - Sep 2024
        </div>
        """,
        unsafe_allow_html=True
    )

if __name__ == "__main__":
    main()

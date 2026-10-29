-- Simply checking for invalid values that might have skipped from data tests

select
    customer_id,
    number_of_orders,
    net_orders,
    net_revenue,
    predicted_clv_project,
    first_order_date,
    most_recent_order_date

from {{ ref('dim_customers') }}

where net_orders > number_of_orders
   or net_revenue < 0
   or predicted_clv_project < 0
   or (net_orders = 0 and predicted_clv_project <> 0)
   or first_order_date > most_recent_order_date
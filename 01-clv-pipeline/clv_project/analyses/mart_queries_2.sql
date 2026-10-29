select count(*) as customers, count(*) filter (where number_of_orders > 0) as with_orders, sum(lifetime_value) as total_ltv from {{ ref('dim_customers') }}

-- CLV of the average customer (customers with at least one net order)
-- CLV of the average customer (customers with at least one net order).

select
    count(*) as customers,
    cast(sum(net_revenue) / sum(net_orders) as decimal(12, 2)) as avg_order_value,
    cast(avg(orders_per_month) as decimal(10, 4)) as orders_per_month,
    {{ var('clv_project_lifespan_months') }} as lifespan_months,
    cast(avg(predicted_clv_project) as decimal(12, 2)) as avg_clv_project

from {{ ref('dim_customers') }}
where net_orders > 0
-- Top 10 customers by lifetime value
with ranked as (
    select 
        customer_id,
        first_name,
        last_name,
        net_orders,
        net_revenue,
        avg_order_value,
        predicted_clv_project,
        row_number() over (order by predicted_clv_project desc, customer_id) as clv_project_rank
    from dim_customers
)

select *
    from ranked
where clv_project_rank <= 10
order by clv_project_rank


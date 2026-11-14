-- Top 10 customers by lifetime value
with ranked as (
    select 
        customer_id,
        first_name,
        last_name,
        net_orders,
        net_revenue,
        avg_order_value,
        predicted_clv,
        row_number() over (order by predicted_clv desc, customer_id) as clv_rank
    from dim_customers
)

select *
    from ranked
where clv_rank <= 10
order by clv_rank


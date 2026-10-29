with orders as (
    select * from {{ ref('int_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

final as (

    select
        orders.order_id,
        orders.customer_id,
        customers.first_name,
        customers.last_name,
        orders.order_date,
        orders.status,
        orders.status in ('returned', 'return_pending') as is_returned,
        orders.amount

    from orders
    left join customers
        on orders.customer_id = customers.customer_id

)
select * from final

with orders as (
 select * from {{ ref('stg_orders') }}
),
payments as (
 select * from {{ ref('stg_payments') }}
),
order_payments as (
 select
 orders.order_id,
 orders.customer_id,
 orders.order_date,
 orders.status,
 payments.amount
 from orders
 left join payments 
    on orders.order_id = payments.order_id
),
final_payments as (
 select
 order_id,
 customer_id,
 order_date,
 sum(case when trim(status) = 'completed' then amount else 0 end) as amount
 from order_payments
 group by 1, 2, 3
)
select * from final_payments
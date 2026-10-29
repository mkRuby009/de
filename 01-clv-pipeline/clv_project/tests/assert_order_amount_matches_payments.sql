with payments_per_order as (
    select
        order_id, sum(amount) as paid_amount
        from {{ ref('stg_payments' )}}
        group by order_id
)

select 
    f.order_id, 
    f.amount as order_amount, 
    coalesce(p.paid_amount, 0) as paid_amount
from {{ ref('fct_orders') }} f
left join payments_per_order p
    on f.order_id = p.order_id
where f.amount <> coalesce (p.paid_amount, 0)
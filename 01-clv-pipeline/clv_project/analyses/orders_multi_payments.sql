select *
from
(
    select
    o.order_id, o.status, p.payment_method,
    row_number() over (partition by o.order_id order by p.payment_id) as payment_occurrence,
    count(*) over (partition by o.order_id) as payments_in_order,
    p.amount
from stg_orders o
join stg_payments p 
    on o.order_id = p.order_id
)temp
where payments_in_order > 1
order by order_id, payment_occurrence



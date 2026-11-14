
-- select * from {{ ref('fct_orders') }}
-- customers who has returned some orders from both tables

select count(*) as orders from {{ ref('fct_orders') }} where is_returned = true


select
    count(*)
from {{ ref('dim_customers') }}
where net_orders <> number_of_orders 


select
    count(*) as customers,
    count(case when net_orders > 0 then 1 end) as buyers,
    sum(net_revenue) as net_revenue,
    max(predicted_clv) as max_clv
from {{ ref("dim_customers")}}

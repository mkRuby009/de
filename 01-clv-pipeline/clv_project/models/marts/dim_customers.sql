/*
* Description: This final table gives one record per customer with the numbers that a business platform needs to check about customers frequently.
* This is the kind of report that a business analyst would use to manage services and marketing better.
* Lifetime value only counts completed orders from our database: placed/shipped, returned orders aren't being considered
*/

-- This report outputs below details:-

--   net orders       = all orders except returned or return_pending ones
--   net revenue      = total paid on net orders
--   avg order value  = net revenue / net orders
--   orders per month = net orders / months covered by the data
--   predicted CLV    = avg order value x orders per month x lifespan months
--
-- Lifespan months is an assumption: var clv_lifespan_months (dbt_project.yml).

with data_window as (

    -- output is just 1 row: count of months the data covers
    -- months from the first to the last order date in the data.
    -- input is date average days per month (365.25 / 12).
    select
        ({{ dbt.datediff('min(order_date)', 'max(order_date)', 'day') }} + 1) / (365.25 / 12) as months
    from {{ ref('fct_orders') }}

),
customer_orders as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        min(o.order_date) as first_order_date,
        max(o.order_date) as most_recent_order_date,
        count(o.order_id) as number_of_orders,
        count(case when not o.is_returned then 1 end) as net_orders,
        coalesce(sum(case when not o.is_returned then o.amount end), 0) as net_revenue,
    from 
        {{ ref('stg_customers') }} c
        left join {{ ref('fct_orders') }} o on c.customer_id = o.customer_id

    group by c.customer_id, c.first_name, c.last_name
),

-- data_window has one row with net orders per month, (about 3.25 months) => orders per customer per month over one fixed period.
-- So we use the cross join to adds the data window months value to every customer 

clv_inputs as (

    -- the one-row observation CTE is attached to every customer
    select
        customer_orders.*,
        -- In case of Customers with no net orders: CLV is 0, since net_revenue is 0. 
        -- nullif stops a division by zero and thus avg_order_value will be null in that case
        net_revenue / nullif(net_orders, 0) as avg_order_value,
        net_orders / data_window.months as orders_per_month

    from customer_orders
    cross join data_window

)

select
    customer_id,
    first_name,
    last_name,
    first_order_date,
    most_recent_order_date,
    number_of_orders,
    net_orders,
    net_revenue,
    cast(avg_order_value as decimal(12, 2)) as avg_order_value,
    cast(orders_per_month as decimal(10, 4)) as orders_per_month,
    cast(
        coalesce(avg_order_value * orders_per_month * {{ var('clv_lifespan_months') }}, 0)
        as decimal(12, 2)
    ) as predicted_clv

from clv_inputs


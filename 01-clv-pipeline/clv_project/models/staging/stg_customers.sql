with source_customers as (
    select *
    from {{ ref('raw_customers') }}
),

renamed as (
    SELECT
    id as customer_id,
    first_name,
    last_name

    from source_customers
)

select * from renamed
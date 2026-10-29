with source as (
    select *
    from {{ ref('raw_payments') }}
),

renamed as (
    select
        id as payment_id,
        order_id,
        payment_method,
        -- amount is stored in cents in the source system
        cast(amount / 100.0 as decimal(12, 2)) as amount
    from source
)

select * from renamed

WITH sales AS
(
    SELECT
        sales_id,
        product_sk,
        customer_sk,
        gross_amount,
        {{ multiply ('unit_price', 'quantity') }} AS calc_gross_amount,
        payment_method

    FROM {{ ref('bronze_sales') }}
),
products AS
(
    SELECT
        product_sk,
        product_name,
        category
    FROM 
        {{ ref('bronze_product') }}
),

customer AS
(
    SELECT
        customer_sk,
        gender
    FROM 
        {{ ref('bronze_customer') }}
),
joined_data AS
(
    SELECT
        sales.sales_id,
        products.product_name,
        products.category,
        customer.gender,
        sales.calc_gross_amount,
        sales.gross_amount
    FROM sales
    JOIN products ON sales.product_sk = products.product_sk
    JOIN customer ON sales.customer_sk = customer.customer_sk
)

SELECT
    category,
    gender,
    sum(gross_amount) AS total_sales
FROM
    joined_data
GROUP BY
    category,
    gender
ORDER BY
    total_sales DESC
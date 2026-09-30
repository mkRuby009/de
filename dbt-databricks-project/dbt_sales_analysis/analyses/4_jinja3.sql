-- incrementally load data from bronze model

{% set inc_flag = true %}
{% set last_load = 3 %}

{% set cols_list = ["date_sk", "sales_id", "gross_amount"] %}

SELECT
    {{ cols_list | join (', ') }}
FROM
    {{ ref ('bronze_sales') }}

{% if inc_flag == true %}
WHERE
    date_sk > {{ last_load }}
{% endif %}

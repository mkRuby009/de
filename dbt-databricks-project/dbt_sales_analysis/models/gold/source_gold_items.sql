WITH dedup_query AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY updateDate DESC) AS dedup_id
    FROM
        {{ source('source', 'sale_items') }}
)

SELECT
    id,
    name,
    category,
    updateDate
FROM
    dedup_query
WHERE
    dedup_id = 1
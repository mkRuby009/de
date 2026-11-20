/*
* Goal: apply the CDC file to dwh.orders so that a second run changes nothing.
*/
\timing on

/*
Step 1: Loading the raw file of CDC messages (JSON lines) into a table (from client side to server database). 
Each line is one JSON document, one row in the table.
RECALL: The file:data/cdc/orders.jsonl was created by pg_recvlogical
*/
-- Raw landing table: one row per line of the CDC file, numbered in file order
CREATE TABLE IF NOT EXISTS dwh.cdc_raw (
  line_no bigint GENERATED ALWAYS AS IDENTITY,
  doc     jsonb  NOT NULL
);

-- Empty it and restart line_no at 1, so the file can be loaded again.
TRUNCATE dwh.cdc_raw RESTART IDENTITY;

-- \copy = psql reads the file (as me) and sends it to the server. One line, no semicolon.
-- Bytes 1 and 2 never occur in JSON, so each whole line arrives as one value.
\copy dwh.cdc_raw (doc) FROM 'data/cdc/orders.jsonl' WITH (FORMAT csv, QUOTE E'\x01', DELIMITER E'\x02')

SELECT doc->>'action' AS action, count(*) FROM dwh.cdc_raw GROUP BY 1 ORDER BY 1;

/* Step 2: applying the change with one MERGE
Only the last change for each key counts. So repeated or old lines in the file do not change the result.
MERGE does INSERT, UPDATE and DELETE for each key in one statement
Most important thing to note is, here update runs only if a value is different. So an idempotent run will update 0 rows.
*/
-- Step 1 (changes): turn each JSON line into one flat object r, e.g. {"order_id": "...", "status": "new"}.
--   wal2json gives a list of {name, type, value} items. A delete has no "columns", only "identity" (the key).
WITH changes AS (
  SELECT line_no,
         doc->>'action' AS action,                      -- I, U or D
         (SELECT jsonb_object_agg(c->>'name', c->'value')
          FROM jsonb_array_elements(coalesce(doc->'columns', doc->'identity')) AS c) AS r
  FROM dwh.cdc_raw
),
-- Step 2 (latest): keep only the LAST change per order. DISTINCT ON keeps the first row
--   of each key in the ORDER BY, and line_no DESC puts the newest line first.
latest AS (
  SELECT DISTINCT ON (r->>'order_id')
         action,
         (r->>'order_id')::uuid          AS order_id,
         (r->>'customer_id')::int        AS customer_id,
         r->>'status'                    AS status,
         (r->>'amount')::numeric(10,2)   AS amount,
         (r->>'created_at')::timestamptz AS created_at,
         (r->>'updated_at')::timestamptz AS updated_at
  FROM changes
  ORDER BY r->>'order_id', line_no DESC
),
-- Step 3 (m): apply to the target in one statement.
m AS (
  MERGE INTO dwh.orders AS t
  USING latest AS s ON t.order_id = s.order_id
  -- the order exists and its last change is a delete
  WHEN MATCHED AND s.action = 'D' THEN
    DELETE
  -- the order exists and some value differs (IS DISTINCT FROM is safe with NULLs)
  WHEN MATCHED AND (t.customer_id, t.status, t.amount, t.created_at, t.updated_at)
       IS DISTINCT FROM (s.customer_id, s.status, s.amount, s.created_at, s.updated_at) THEN
    UPDATE SET customer_id = s.customer_id, status = s.status, amount = s.amount,
               created_at = s.created_at, updated_at = s.updated_at
  -- the order is new (and was not deleted again)
  WHEN NOT MATCHED AND s.action <> 'D' THEN
    INSERT VALUES (s.order_id, s.customer_id, s.status, s.amount, s.created_at, s.updated_at)
  RETURNING merge_action() AS merge_action              -- INSERT, UPDATE or DELETE per row
)
-- Report: how many rows each action changed. A second run must return 0 rows.
SELECT merge_action, count(*) AS rows_changed FROM m GROUP BY 1 ORDER BY 1;

/* step 3: Proving that source and target are now identical. 
   The source: orders table 
   the target: dwh.orders
   Join all rows into one long string in key order, then reduce it to one md5 value.
  If any row differs between source and target, the two values differ.
*/
SELECT 'source public.orders' AS side, count(*),
       md5(string_agg(order_id || status || amount || updated_at, ',' ORDER BY order_id)) AS checksum
FROM public.orders
UNION ALL
SELECT 'target dwh.orders', count(*),
       md5(string_agg(order_id || status || amount || updated_at, ',' ORDER BY order_id))
FROM dwh.orders;
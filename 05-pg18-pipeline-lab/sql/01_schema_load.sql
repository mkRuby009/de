
\timing on
-- Stop at the first error. One mistake then gives one error, not a chain of errors.
\set ON_ERROR_STOP on
 
-- Reset: remove tables from previous, so this file can run again and again.
DROP TABLE IF EXISTS events CASCADE;                                  -- the parent and all its partitions
DELETE FROM partman.part_config WHERE parent_table = 'public.events';  -- pg_partman's settings row for events
DROP TABLE IF EXISTS partman.template_public_events;                   -- the template table pg_partman made
DROP TABLE IF EXISTS orders, customers CASCADE;
 
-- Normal base tables for the shop database
CREATE TABLE customers (
  customer_id int         PRIMARY KEY,
  name        text        NOT NULL,
  country     text        NOT NULL,
  -- timestamptz stores a point in time (UTC inside). psql shows it in the session time zone.
  updated_at  timestamptz NOT NULL
);
 
CREATE TABLE orders (
  order_id    uuid          PRIMARY KEY DEFAULT uuidv7(),
  customer_id int           NOT NULL REFERENCES customers,
  status      text          NOT NULL,
  amount      numeric(10,2) NOT NULL,
  created_at  timestamptz   NOT NULL,
  updated_at  timestamptz   NOT NULL
);
 
-- Parent table Partitioned table for order events: each row goes to the partition for its month.
-- The primary key thus includes the partition key (event_time).
CREATE TABLE events (
  event_id    uuid          NOT NULL DEFAULT uuidv7(),
  event_time  timestamptz   NOT NULL,
  customer_id int           NOT NULL,
  event_type  text          NOT NULL,
  amount      numeric(10,2),
  PRIMARY KEY (event_id, event_time)
) PARTITION BY RANGE (event_time);
 
-- pg_partman creates the partitions and records the table in partman.part_config.
-- p_default_table is not clear to me 
SELECT partman.create_partition(
  p_parent_table    := 'public.events',   -- table to manage (schema.table)
  p_control         := 'event_time',      -- the partition key column
  p_interval        := '1 month',         -- size of one partition
  p_start_partition := '2025-10-01',      -- first partition to create
  p_premake         := 2,                 -- keep 2 future partitions ready
  p_default_table   := false);            -- no catch-all partition ??
 
-- 50,000 customers. generate_series gives one row per number g.
-- (ARRAY[...])[n] picks the n-th word. Arrays start at 1.
INSERT INTO customers
SELECT g, 'customer_' || g, (ARRAY['IN', 'US', 'DE', 'AE', 'SG'])[1 + g % 5], now()
FROM generate_series(1, 50000) AS g;
 
-- 200,000 orders. hashint4(g) gives the same "random" value on every run.
INSERT INTO orders (customer_id, status, amount, created_at, updated_at)
SELECT 1 + abs(hashint4(g)::bigint) % 50000,                              -- customer 1..50000
       (ARRAY['new', 'paid', 'shipped', 'delivered', 'cancelled'])[1 + abs(hashint4(g + 1)::bigint) % 5],
       round((abs(hashint4(g + 2)::bigint) % 50000) / 100.0, 2),          -- amount 0.00..499.99
       timestamptz '2026-09-01 00:00:00+00' + g * interval '10 seconds',  -- one order every 10 s
       timestamptz '2026-09-01 00:00:00+00' + g * interval '10 seconds'
FROM generate_series(1, 200000) AS g;
 
-- Step A: write a CSV file with 5M events, in time order (one event every 6.3 s for 12 months).
-- COPY ... TO runs on the server, as the Linux user postgres. It overwrites an old file.
COPY (
  SELECT timestamptz '2025-10-01 00:00:00+00' + g * interval '6307 milliseconds' AS event_time,
         1 + abs(hashint4(g)::bigint) % 50000 AS customer_id,
         (ARRAY['view', 'view', 'view', 'cart', 'buy'])[1 + abs(hashint4(g + 1)::bigint) % 5] AS event_type,
         round((abs(hashint4(g + 2)::bigint) % 20000) / 100.0, 2) AS amount
  FROM generate_series(0, 4999999) AS g
) TO '/var/lib/postgresql/lab/events.csv' WITH (FORMAT csv, HEADER);
 
-- Step B: bulk-load the file. event_id is not in the file: the uuidv7() default fills it.
COPY events (event_time, customer_id, event_type, amount)
FROM '/var/lib/postgresql/lab/events.csv' WITH (FORMAT csv, HEADER);
 
-- Updating the planner statistics (pg_statistic) for the above tables
ANALYZE customers;
ANALYZE orders;
ANALYZE events;
 
-- Check: row counts and number of partitions
SELECT (SELECT count(*) FROM customers) AS customers,
       (SELECT count(*) FROM orders)    AS orders,
       (SELECT count(*) FROM events)    AS events,
       (SELECT count(*) FROM partman.show_partitions('public.events')) AS partitions;

SELECT count(*) AS partitions, min(partition_tablename) AS first, max(partition_tablename) AS last
FROM partman.show_partitions('public.events');

SELECT partition_tablename FROM partman.show_partitions('public.events');

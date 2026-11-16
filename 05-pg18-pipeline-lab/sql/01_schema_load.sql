\timing on
!-- Normal base tables for the shop database
CREATE TABLE customers(
    customer_id int PRIMARY_KEY,
    name        text NOT NULL,
    country     text NOT NULL,
    !-- Using timestamptz to store timestamp in UTC and handle time-zone automatically on retreival
    updated_at timestamptz NOT NULL
);

CREATE TABLE orders(
    order_id uuid PRIMARY_KEY DEFAULT uuidv7(),
    customer_id int NOT NULL REFERENCES customers,
    status text NOT NULL,
    amount numeric(10,2) NOT NULL,
    created_at  timestamptz  NOT NULL,
    updated_at  timestamptz  NOT NULL
);

!-- Partitioned table for order events
CREATE TABLE events(
    event_id uuid PRIMARY KEY DEFAULT uuidv7(),
    event_time timestamptz NOT NULL,
    customer_id int NOT NULL,
    event_type text NOT NULL,
    amount numeric(10,2),
    PRIMARY KEY (event_id, event_time),
) PARTITION BY RANGE (event_time);

SELECT partman.create_partition()

!-- Generating customer data and order data for testing
INSERT INTO customers
SELECT g, 'customer_' || g, (ARRAY['IN', 'US', 'DE', 'AE', 'SG'])[1 + g % 5], now()
FROM generate_series(1, 50000) AS g;

INSERT INTO orders (customer_id, status, amount, created_at, updated_at)
SELECT 1 + abs(hashint4(g)::bigint) % 50000,
       (ARRAY['new', 'paid', 'shipped', 'delivered', 'cancelled'])[1 + abs(hashint4(g + 1)::bigint) % 5],
       round((abs(hashint4(g + 2)::bigint) % 50000) / 100.0, 2),
       timestamptz '2026-09-01 00:00:00+00' + g * interval '10 seconds',
       timestamptz '2026-09-01 00:00:00+00' + g * interval '10 seconds'
FROM generate_series(1, 200000) AS g;

!-- Generating order events data for testing
COPY (
  SELECT timestamptz '2025-10-01 00:00:00+00' + g * interval '6307 milliseconds' AS event_time,
         1 + abs(hashint4(g)::bigint) % 50000 AS customer_id,
         (ARRAY['view', 'view', 'view', 'cart', 'buy'])[1 + abs(hashint4(g + 1)::bigint) % 5] AS event_type,
         round((abs(hashint4(g + 2)::bigint) % 20000) / 100.0, 2) AS amount
  FROM generate_series(0, 4999999) AS g
) TO '/var/lib/postgresql/lab/events.csv' WITH (FORMAT csv, HEADER);

COPY events (event_time, customer_id, event_type, amount)
FROM '/var/lib/postgresql/lab/events.csv' WITH (FORMAT csv, HEADER);

!-- Just updating the pg_statistic for above tables
ANALYZE customers;
ANALYZE orders;
ANALYZE events;
/*
FILE COMMENT: This script was not run directly, each step was run in psql, and the output was checked. The steps are now in this file for the flow.
 
Script Goal: Capture every insert, update and delete on public.orders with a logical replication slot (cdc_orders)
             that decodes the WAL with the wal2json output plugin.
             Before any change is read, dwh.orders gets a full copy of orders (the initial snapshot).
             Later, pg_recvlogical (Step 7, Terminal 2) streams the changes as JSON lines into data/cdc/orders.jsonl,
             and Phase 3 applies that file to dwh.orders.
*/
 
/*
Step 1: Creation of slot cdc_orders using the wal2json output plugin (a plugin that a slot loads, not an extension: no CREATE EXTENSION)
 
pg_create_logical_replication_slot creates a logical replication slot that decodes with the output plugin we name (here wal2json).
From its start position on, it retains Write-Ahead Log (WAL) data until a consumer reads the changes AND confirms them,
returning the slot_name and the initial lsn (the WAL position where the slot starts).
Expected here: ERROR: library "wal2json" may not be used as an output plugin (fixed in Step 2).
*/
SELECT * FROM  pg_create_logical_replication_slot('cdc_orders', 'wal2json');
 
/*
Step 2: Reloading required plugins
Terminal 2 first: add  output_plugin_libraries = 'pgoutput, test_decoding, wal2json'  to conf/lab.conf, then
                  sudo cp conf/lab.conf /etc/postgresql/18/lab/conf.d/lab.conf
INTERESTING TO NOTE:
 Before 18.6, a user with the REPLICATION right could make the server load any library as a plugin.
 Since 18.6, only listed plugins (in output_plugin_libraries) load, so we add each one that is trusted. Default list: pgoutput, test_decoding.
 The setting output_plugin_libraries needs no restart (cool!). pg_reload_conf() signals the server to read its config files again!!
*/
SELECT pg_reload_conf();
SHOW output_plugin_libraries;
SELECT * FROM pg_create_logical_replication_slot('cdc_orders', 'wal2json');
 
/*Step 3: Checking pgoutput (pgoutput is the plugin that PostgreSQL's own logical replication uses, and the one Debezium reads)
pgoutput sends binary messages, and only for the tables in a publication (publication is a named list of tables)
*/
-- A throwaway table, so this test does not touch orders
CREATE TABLE cdc_probe (id int PRIMARY KEY, note text);
-- pgoutput needs this one: its publication_names option says which publication (= which tables) to send
CREATE PUBLICATION probe_pub FOR TABLE cdc_probe;
 
/*Creating a slot only sets its start position. Nothing is decoded until someone reads the slot:
  either with the SQL functions (peek/get, used below) or over a replication connection (pg_recvlogical, Debezium).*/
 
SELECT slot_name FROM pg_create_logical_replication_slot('pgoutput_demo', 'pgoutput');
INSERT INTO cdc_probe VALUES (1, 'hello');
 
-- Peek at the raw messages. The first byte of each message is its type.
-- pgoutput output is binary, so the _binary_ version of peek is needed.
SELECT lsn, chr(get_byte(data, 0)) AS msg_type, length(data) AS bytes, encode(data, 'escape') AS raw
FROM pg_logical_slot_peek_binary_changes('pgoutput_demo', NULL, NULL,
       'proto_version', '1', 'publication_names', 'probe_pub');
 
 
-- Clean up. Caution: leaving a test slot behind holds WAL unnecessarily, and can fill the disk!
SELECT pg_drop_replication_slot('pgoutput_demo');
DROP PUBLICATION probe_pub;
DROP TABLE cdc_probe;
 
/* Step 4: Copy orders to the target (initial snapshot). The cdc_orders slot already exists,
 so every change from now on waits in the slot: the copy and the stream leave no gap.
 INCLUDING ALL = NOT NULL, defaults and indexes (with the primary key). Foreign keys are not copied!
 CREATE TABLE dwh.orders AS SELECT * FROM public.orders;  -- copies only column names, types and data: no NOT NULL, no default, no primary key
*/
CREATE SCHEMA dwh;
CREATE TABLE dwh.orders (LIKE public.orders INCLUDING ALL);
INSERT INTO dwh.orders SELECT * FROM public.orders;
 
/* Step 5: This is a crucial step. Simulating the app: it writes changes to orders while CDC reader (pg_recvlogical in this project, started in Step 7) is not running yet.
    = a CDC consumer that is down for a while.
    WAL is written for every change anyway. The slot makes the server KEEP that WAL, because no reader has confirmed it yet.
    So nothing is lost: when the reader starts, it gets all 1,600 changes. The cost: WAL builds up on disk (Step 6 shows how much).
    The values come from hashint4, so they look random but are the same on every run.
*/
-- Generating 1,000 new orders
INSERT INTO orders(customer_id, status, amount, created_at, updated_at)
SELECT 1 + abs(hashint4(g + 900000)::bigint) % 50000, 'new',
       round((abs(hashint4(g + 900001)::bigint) % 50000) / 100.0, 2), now(), now()
FROM generate_series(1, 1000) AS g;
 
-- Changing status of 500 orders (paid -> shipped). Like every change, this is decoded from the WAL that the cdc_orders slot keeps.
UPDATE orders SET status = 'shipped', updated_at = now()
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'paid' ORDER BY order_id LIMIT 500);
 
-- Deleting 100 cancelled orders to add up more change in CDC. A delete line in the CDC output carries only the key (the primary key = replica identity).
DELETE FROM orders
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'cancelled' ORDER BY order_id LIMIT 100);

/* Step 6: Checking how much WAL the slot (cdc_orders) has kept. The slot's restart_lsn is the oldest WAL that the server must keep for this slot.
-- Peek = read the waiting changes but leave them in the slot.
-- NULL, NULL = no end position(upto_lsn), no row limit(upto_nchanges). The rest are VARIADIC options for plugin wal2json:
-- format-version 2      one JSON object per row change
-- include-transaction   false = no begin/commit lines
-- add-tables            only changes on public.orders
*/

SELECT count(*) FROM pg_logical_slot_peek_changes('cdc_orders', NULL, NULL,
    'format-version', '2', 'include-transaction', 'false', 'add-tables', 'public.orders');

SELECT data FROM pg_logical_slot_peek_changes('cdc_orders', NULL, NULL,
  'format-version', '2', 'include-transaction', 'false', 'add-tables', 'public.orders') LIMIT 2;


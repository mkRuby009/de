/*
* Goal: Queries on Partitioned table: 
        1) Testing fast reads using partition Pruning, BRIN index vs B-Tree index. (all favorite topics clubbed ;-))
        2) Managing monthly upkeep
        
* Learning: Partition pruning is a powerful feature which can significantly improve query performance on large partitioned tables. 
            BRIN indexes are efficient for large tables with sequentially correlated data;
            B-Tree indexes are more versatile but may require more storage and maintenance.
  NOTE: the script only lists queries, Inot run it as it is instead ran all steps manually to debug better
*/
/*
Step 1: Test a event query with and without partition pruning
*/
\timing on
-- Total size of all partitions of events.
SELECT pg_size_pretty(sum(pg_relation_size(relid))) AS events_size FROM pg_partition_tree('events');

-- Store the test query in the psql variable q. :q pastes it back. Inside the quotes, each ' is doubled.
\set q 'SELECT count(*), sum(amount) FROM events WHERE event_time >= ''2026-03-15 10:00+00'' AND event_time < ''2026-03-15 11:00+00'''

-- Pruning ON (default). Run it twice: the 1st run reads pages into the cache, the 2nd shows the steady time.
-- Expect: the plan shows only event for partition for march month
EXPLAIN (ANALYZE, COSTS OFF) :q;
EXPLAIN (ANALYZE, COSTS OFF) :q;

-- Pruning OFF, for comparison only. the plan will list all 16 partitions.
SET enable_partition_pruning = off;
EXPLAIN (ANALYZE, COSTS OFF) :q;
EXPLAIN (ANALYZE, COSTS OFF) :q;
RESET enable_partition_pruning;

-- Running the saved query itself
:q;

/*
* Step 2:  BRIN vs B-tree index on event_time
*/
-- BRIN: stores only the min and max event_time per range of 128 pages. Tiny.
-- An index on a partitioned table makes one index per partition: pg_partition_tree adds up their sizes.
CREATE INDEX events_time_brin ON events USING brin (event_time);
SELECT pg_size_pretty(sum(pg_relation_size(relid))) AS brin_size FROM pg_partition_tree('events_time_brin');
EXPLAIN (ANALYZE, COSTS OFF) :q;   -- 1st run: warms the cache
EXPLAIN (ANALYZE, COSTS OFF) :q;   -- 2nd run: compare this one. Look for: Bitmap Heap Scan, Heap Blocks: lossy
DROP INDEX events_time_brin;

-- B-tree: one entry per row, sorted. Fast, and large.
CREATE INDEX events_time_btree ON events (event_time);
SELECT pg_size_pretty(sum(pg_relation_size(relid))) AS btree_size FROM pg_partition_tree('events_time_btree');
EXPLAIN (ANALYZE, COSTS OFF) :q;
EXPLAIN (ANALYZE, COSTS OFF) :q;   -- check for: Index Scan

-- A whole month: every row of the partition matches. Does the planner still use the index?
EXPLAIN (ANALYZE, COSTS OFF)
SELECT count(*), sum(amount) FROM events
WHERE event_time >= '2026-03-01 00:00+00' AND event_time < '2026-04-01 00:00+00';
DROP INDEX events_time_btree;

-- Keeping BRIN for the rest of the lab.
CREATE INDEX events_time_brin ON events USING brin (event_time);

/*
* Step 3: Managing monthly upkeep: create the next months' partitions on a schedule.
  NOTE: the partition for a month must exist before its rows arrive. With no default partition, an insert that fits no partition fails. 
  ->partman.run_maintenance_proc() makes the next partitions (and drops old ones, if you set a retention). 
  ->pg_cron runs it on a schedule inside the database, so no outside cron or Airflow job is needed
*/
/*
 cron.schedule(job name, schedule, SQL command). $$ ... $$ quotes the command.
 run_maintenance_proc() creates the partitions that will be needed soon.
 Testing every 30 seconds here, to check one run quickly.
 */
SELECT cron.schedule('partman-maintenance', '30 seconds', $$CALL partman.run_maintenance_proc()$$);
SELECT pg_sleep(35);

-- The job log. Expect: status = succeeded.
SELECT j.jobname, d.status, d.return_message, d.start_time
FROM cron.job_run_details d JOIN cron.job j USING (jobid)
ORDER BY d.start_time DESC LIMIT 3;

-- Same job name = the job is changed, not added. '0 * * * *' = minute 0 of every hour.
SELECT cron.schedule('partman-maintenance', '0 * * * *', $$CALL partman.run_maintenance_proc()$$);
SELECT jobname, schedule, command, username FROM cron.job;

/*
* Step 4: retire the oldest month data/partition concurrently (without blocking the app)
*/
-- Find the oldest partition and build its archive file name.
-- \gset stores each output column in a psql variable of the same name (oldest, archive_file).
SELECT partition_schemaname || '.' || partition_tablename AS oldest,
       '/var/lib/postgresql/lab/archive/' || partition_tablename || '.csv' AS archive_file
FROM partman.show_partitions('public.events') LIMIT 1 \gset

-- Detach: the partition becomes a normal table. CONCURRENTLY = reads and writes on events go on.
ALTER TABLE events DETACH PARTITION :oldest CONCURRENTLY;
-- Archive it to a CSV file on the server, then drop it. (:oldest = table name, :'archive_file' = quoted string)
COPY :oldest TO :'archive_file' WITH (FORMAT csv, HEADER);
DROP TABLE :oldest;

SELECT count(*) AS partitions_left, min(partition_tablename) AS first
FROM partman.show_partitions('public.events');


/*
* Goal: diagnosing when the replication slot dies and why postgres allows it to die.
* Learning: a slot keeps WAL until its reader confirms it. A reader that is down, or a slot that nobody uses, makes WAL grow until the disk is full.
             A full WAL disk stops the whole server. PostgreSQL has 2 guards for WAL: a size limit (max_slot_wal_keep_size) and, new in PG 18(cool Elephant!), an idle-time limit (idle_replication_slot_timeout). 
             When a guard acts, the slot is invalidated: the server stays safe, but the CDC stream is broken and needs a new snapshot.
*/
/* ===================================max_slot_wal_keep_size Guard ========================================= */
/* Step1: Stopping the CDC reader (pg_recvlogical) in Terminal 2. It is not reading the slot, so WAL builds up on disk.*/

/* Step 2: Write about 300 MB of WAL while no reader runs.
*
*/
-- BEFORE. safe_wal_size = how much more WAL can be written before the slot is at risk.
SELECT slot_name, active, wal_status,
    pg_size_pretty(safe_wal_size) AS safe_wal_size,
    invalidation_reason
FROM pg_replication_slots;

-- 2M rows of padding. Its only job is to write about 300 MB of WAL.
CREATE TABLE wal_filler AS
SELECT g, repeat('x', 100) AS pad FROM generate_series(1, 2000000) AS g;

-- Over the limit, before any checkpoint: expect unreserved, negative safe_wal_size
SELECT slot_name, active, wal_status,
    pg_size_pretty(safe_wal_size) AS safe_wal_size,
    invalidation_reason
FROM pg_replication_slots;

-- closing the current wal file
SELECT pg_switch_wal();

-- Feeling crazy! forcing a checkpoint now...
CHECKPOINT;

--AFTER checkpoint : a check after WAL removal
SELECT slot_name, active, wal_status,
    pg_size_pretty(safe_wal_size) AS safe_wal_size,
    invalidation_reason
FROM pg_replication_slots;

DROP TABLE wal_filler;

/*
Step 3: Confirming that the slot is invalidated.
    try restarting the CDC reader (pg_recvlogical) in Terminal 2.
    It failed with ERROR: manasi@shop DETAIL:  This replication slot has been invalidated due to "wal_removed".
*/

/* ===================================idle_replication_slot_timeout Guard =========================================
idle_replication_slot_timeout gives up slots that no reader used for that long, even when they hold little WAL.
It cleans up slots left behind by old tools and tests. The check runs at a checkpoint, so the code forces one.
*/

-- A slot that nobody will read.
SELECT * FROM pg_create_logical_replication_slot('forgotten_slot', 'wal2json');

-- ALTER SYSTEM writes the value to postgresql.auto.conf. 30 s is a lab value: use hours or days in production.
ALTER SYSTEM SET idle_replication_slot_timeout = '30s';
SELECT pg_reload_conf();                -- make the server read the new value
SELECT pg_sleep(35);                    -- wait longer than the timeout
SHOW idle_replication_slot_timeout;
CHECKPOINT;                             -- idle slots are given up at a checkpoint

-- inactive_since = when the slot lost its last reader.
SELECT slot_name, active, wal_status, inactive_since, invalidation_reason
FROM pg_replication_slots ORDER BY slot_name;

-- Clean up: remove the setting, then drop both dead slots.
ALTER SYSTEM RESET idle_replication_slot_timeout;
SELECT pg_reload_conf();
SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots;
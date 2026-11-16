# PostgreSQL 18 pipeline lab: CDC and partitioning

This is a practice project to implement CDC purely using postgres and extensions.

## Stack
 
PostgreSQL 18.7  
Extensions: wal2json, pg_partman, pg_cron

[pg_partman](https://github.com/pgpartman/pg_partman): an extension to create and manage both time-based and number-based table partition sets.
 
## Repository
 
```text
conf/lab.conf    server settings for the lab cluster
sql/             one file per phase: load, CDC, apply, slot risks, big tables
NOTES.md         my raw numbers, what I expected, and the mistakes I made
```

## Why this project?

Postgres is where I like to try things out, so I built the smallest CDC pipeline I could on a local PostgreSQL 18: a replication slot, the wal2json plugin, pg_recvlogical and plain SQL. Then I broke it on purpose to see how it fails.

CDC in Postgres works in 4 parts:

WAL (write-ahead log): Postgres writes every change here first.
Logical decoding: turns WAL records into row changes.
Replication slot: remembers how far the reader has got, and keeps the WAL the reader still needs.
Output plugin: sets the format of the changes. pgoutput is the built-in binary protocol. wal2json gives JSON.

Compared with a batch query on updated_at, CDC also catches deletes, keeps the order of changes, and does not scan tables again and again.

## Settings
![alt text](pg_settings.png)

## Data
An online shop data (created using generate_series) with 3 tables.  
orders is the app's table, which CDC reads in Phase 2.  
events is a big table with 5M rows, split by month.
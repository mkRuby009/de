
# PostgreSQL 18 pipeline lab: CDC and partitioning
 
A practice project: change data capture (CDC) built with only Postgres and three extensions, plus the partitioning work that a growing events table needs.
 
**Goal:** show, with numbers, that I can move data out of and into PostgreSQL 18 safely, and keep a big table fast.
 
## Why this project?
 
I wanted to understand CDC before I put a tool like Debezium in front of it. What does Postgres do when a row changes? Where does the change go, who keeps track of it, and what breaks when the consumer falls behind?
 
Postgres is where I like to try things out, so I built the smallest CDC pipeline I could on a local PostgreSQL 18: a replication slot, the wal2json plugin, `pg_recvlogical` and plain SQL. Then I broke it on purpose to see how it fails.
 
## How CDC works in Postgres
 
| Part | Job |
| --- | --- |
| WAL (write-ahead log) | Postgres writes every change here first. |
| Logical decoding | Turns WAL records back into row changes. |
| Replication slot | Remembers how far the reader has got, and keeps the WAL the reader still needs. |
| Output plugin | Sets the format of the changes. `pgoutput` is the built-in binary protocol. `wal2json` gives JSON. |
 
Compared with a batch query on `updated_at`, CDC also catches deletes, keeps the order of changes, and does not scan tables again and again.
 
## What the lab does
 
```
TODO: Upload smartdraw flow image here
```
 
## Stack
 
PostgreSQL 18.7 on Ubuntu 24.04, in a separate local cluster (port 5434).
 
| Extension / tool | What it is for in general | What I use it for here |
| --- | --- | --- |
| [wal2json](https://github.com/eulerto/wal2json) | An output plugin for logical decoding. It turns the changes in the WAL into JSON. A replication slot loads it, so there is no `CREATE EXTENSION`. | To read every insert, update and delete on `orders` as one JSON line. |
| [pg_partman](https://github.com/pgpartman/pg_partman) | Creates and manages time-based and number-based partition sets. It makes future partitions ahead of time and can drop old ones. | Monthly partitions for `events`, created 2 months ahead. |
| [pg_cron](https://github.com/citusdata/pg_cron) | A cron-style job scheduler that runs inside the database. A job is a SQL command on a schedule. | Runs the pg_partman upkeep every hour. |
| [pg_recvlogical](https://www.postgresql.org/docs/18/app-pgrecvlogical.html) | A client tool that ships with Postgres. It streams changes from a logical replication slot. | The CDC reader: it writes the JSON changes to a file. |
 
## Data
 
A small online shop, generated with `generate_series`, so every run gives the same data.
 
| Table | Rows | Role |
| --- | --- | --- |
| `customers` | 50,000 | Lookup table |
| `orders` | 200,000 | The app's table. CDC reads its changes. |
| `events` | 5,000,000 | Big, time-ordered table, partitioned by month |
 
## Settings
 
Only five settings differ from a default cluster ([conf/lab.conf](conf/lab.conf)). The one that matters most is `wal_level = logical`: without it, the WAL does not hold enough detail for CDC.
 
![Lab cluster settings from pg_settings](pg_settings.png)
 
## How this maps to real CDC stacks
 
| In this lab | In production |
| --- | --- |
| Replication slot + output plugin | Every Postgres CDC tool reads through a slot. Debezium, Fivetran, Airbyte and Google Datastream use `pgoutput` with a publication. AWS DMS uses `pglogical` or `test_decoding`. |
| wal2json | I use it because its output is easy to read. The lab also looks at raw `pgoutput` messages, which is what the tools receive. |
| Slot guards (`max_slot_wal_keep_size`, PG 18 `idle_replication_slot_timeout`) | They protect the source database's disk when a consumer stops. |
| Slot first, then snapshot, then idempotent `MERGE` | The same start-up order that CDC tools use: first a snapshot, then the stream. Spark does the apply with `MERGE INTO` on Delta and Iceberg tables. |
| pg_partman + pg_cron | AWS documents this pair for partition upkeep on RDS and Aurora. |
| Detach and drop a partition | The standard way to remove old logs and events. Much faster than a bulk `DELETE`. |
| BRIN index | For very large tables where a column follows the row order on disk, such as event time. |
 
The common stacks are Debezium on Kafka Connect (open source), AWS DMS or Google Datastream (cloud-managed), and Fivetran or Airbyte (SaaS). The Postgres side is the same for all of them: slots, WAL retention, the first snapshot and an idempotent apply. This lab covers that side.
 
## Progress
 
- [x] Phase 0: lab cluster and settings
- [ ] Phase 1: schema, partitions, bulk load
- [ ] Phase 2: CDC with a replication slot
- [ ] Phase 3: idempotent apply with `MERGE`
- [ ] Phase 4: slot failure modes
- [ ] Phase 5: pruning, BRIN vs B-tree, retention  
Results and all the learnings from above all phases once tested OK.
 
## Repository
 
```text
conf/lab.conf    server settings for the lab cluster
sql/             one file per phase: load, CDC, apply, slot risks, big tables
NOTES.md         my raw numbers, what I expected, and the mistakes I made
```
 

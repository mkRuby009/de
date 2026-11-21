# Iceberg vs Delta Lake with Spark

**Status:** in progress.

**Objective:** Which table format handles repeated writes and OLAP scans better, and how much does maintenance win back?

## Plan

Same Spark, same data, same partitioning (by day), same target file size. Only the table format changes.

1. **Repeated writes.** Load 50 small batches into each table: half as appends, half as MERGEs.
2. **Scans.** Run the same time-range query on both tables.
3. **Maintenance.** Iceberg: `rewrite_data_files` and `expire_snapshots`. Delta: `OPTIMIZE` and `VACUUM`. Then run the query again.

**Data:** the 5M events from [04](../04-pg18-pipeline-lab), exported to Parquet.

## Results

| Measure | Iceberg | Delta Lake |
|---|---|---|
| Data files after 50 batches | | |
| Metadata or log files after 50 batches | | |
| Files read by the time-range query | | |
| Query time, before maintenance | | |
| Data files after maintenance | | |
| Query time, after maintenance | | |
| How a MERGE stored an update (file rewrite, delete file, or deletion vector) | | |

## Already done

[spark-iceberg-hands-on](spark-iceberg-hands-on): a feature tour of Iceberg on a small table. Hidden partitioning, schema and partition evolution, snapshots, time travel, rollback, and MERGE.
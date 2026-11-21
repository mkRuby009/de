# Data Engineering Projects
 
Batch and OLAP workloads. Each folder is a full project with an intended Project Objective,
a setup, and the observations.
 
Stack across the repo: PySpark, Airflow, dbt, PostgreSQL, Snowflake, Iceberg, Delta Lake, Docker.
 
| # | Project | Project Objective | Stack | Observations |
|---|---------|--------------------|-------|--------|
| [01](01-clv-pipeline) | Customer Lifetime Value (CLV) Pipeline | turn raw shop exports into a tested per-customer CLV table, and refresh it daily with Airflow | dbt, DuckDB, Airflow 3 | Test-gated daily builds, with per-order payment reconciliation; Separate dev and prod DuckDB files, so editor queries do not lock scheduled runs |
| [02](02-iceberg-vs-delta-with-Spark) | Iceberg vs Delta Lake with Spark| Which table format handles repeated writes and OLAP scans better? | PySpark, Iceberg, Delta Lake, Parquet | *fill in* |
| [03](03-scd2-snapshot-stream-log) | SCD Type 2: Snapshot vs Stream vs Log | build one SCD Type 2 dimension three ways, and find which build keeps every version | Snowflake, dbt, Snowflake Streams | Snapshot and stream both lost a version changed twice between reads, giving a wrong point-in-time join; Change log kept every version, verified by 6 dbt tests |
| [04](04-pg18-pipeline-lab) | PostgreSQL 18 CDC and Partitioning | build CDC on native Postgres, and keep a large partitioned table fast and maintained | PostgreSQL 18, wal2json, pg_partman, pg_cron | Replay-safe CDC, with slot failure modes reproduced; Partition pruning and BRIN for fast time-range reads |
| [05](05-spark-tuning-exercises) | Spark Tunning excercises | AQE, lots more | PySpark | *fill in* |
| [06](06-spark-connect-usecase) | Spark Spark Connect | Spark connect usecase | PySpark, Spark Connect | *fill in* |
 
---
 
Copyright (c) 2026 [mkruby009]. All rights reserved.

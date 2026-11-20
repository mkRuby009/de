# Data Engineering Projects
 
Batch and OLAP workloads. Each folder is a full project with a intended Project Objective,
a setup, and a measured result.
 
Stack across the repo: PySpark, Airflow, dbt, PostgreSQL, Snowflake, Iceberg, Delta Lake, Docker.
 
| # | Project | Project Objective | Stack | Observations |
|---|---------|--------------------|-------|--------|
| [01](01-clv-pipeline) | Customer Lifetime Value (CLV) Pipeline | build, test and schedule a CLV report pipeline end to end | dbt, DuckDB, Airflow | 34/34 dbt nodes computed; Calculated average predicted CLV $194.92 (24-month lifespan) |
| [02](02-lakehouse-iceberg-vs-delta) | Iceberg vs Delta Lake | Which table format handles repeated writes and OLAP scans better? | PySpark, Iceberg, Delta Lake, Parquet | *fill in* |
| [03](04-scd2-dbt-snowflake) | SCD Type 2 | dbt snapshot or hand-written merge? | PySpark, dbt, Snowflake | *fill in* |
| [04](04-pg18-pipeline-lab) | PostgreSQL 18 CDC and Partitioning | build CDC on native Postgres, and keep a large partitioned table fast and maintained | PostgreSQL 18, wal2json, pg_partman, pg_cron | Replay-safe CDC, with slot failure modes reproduced; Partition pruning and BRIN for fast time-range reads |
| [05](05-spark-tuning-exercises) | Spark Tunning excercises | AQE, lots more | PySpark | *fill in* |
| [06](06-spark-connect-usecase) | Spark Spark Connect | Spark connect usecase | PySpark, Spark Connect | *fill in* |
 
---
 
Copyright (c) 2026 [mkruby009]. All rights reserved.

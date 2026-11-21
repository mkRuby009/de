# Data Engineering Projects
 
Batch and OLAP workloads. Repo has numbered projects with an intended Project Objective,
result, and the observations/Learnings.
 
## Finished Projects
 
| # | Project | Objective | Stack | Observations |
|---|---|---|---|---|
| [01](01-clv-pipeline) | Customer Lifetime Value (CLV) Pipeline | Turn raw shop exports into a tested per-customer CLV table, refreshed daily with Airflow | dbt, DuckDB, Airflow 3 | Daily build is test-gated, including a payments-to-orders check |
| [03](03-scd2-snapshot-stream-log) | SCD Type 2: Snapshot vs Stream vs Log | Build one SCD Type 2 dimension three ways, and find which build keeps every version | Snowflake, dbt, Snowflake Streams | Only the change log kept every version; snapshot and stream missed quick double updates |
| [04](04-pg18-pipeline-lab) | PostgreSQL 18 CDC and Partitioning | Build CDC on native Postgres, and keep a large partitioned table fast and maintained | PostgreSQL 18, wal2json, pg_partman, pg_cron | Replay-safe CDC; partition pruning keeps time-range reads fast |
| [06](06-spark-connect-usecase) | Spark Connect: Thin Client, Remote Driver | Run Spark from a thin client while the driver stays on the cluster, and see what crosses the wire | PySpark, Spark Connect, Docker | `<one line from your results>` |
 
## WIP
 
| # | Project | Objective | Stack |
|---|---|---|---|
| [02](02-iceberg-vs-delta-with-Spark) | Iceberg vs Delta Lake with Spark | Which table format handles repeated writes and OLAP scans better? | PySpark, Iceberg, Delta Lake, Parquet |
| [05](05-spark-tuning-exercises) | Spark Tuning: Where a Job Loses Time | Find where a Spark job loses time (reads, shuffle, joins, skew, spill) and which setting fixes each | PySpark |
 
## Learning Curve Projects
 
Few Projects commited as built, with learning mistakes, flow included.
 
- [airflow-3-full-latest-project](airflow-3-full-latest-project): one DAG per Airflow 3 feature
- [dbt-databricks-project](dbt-databricks-project): dbt on Databricks, with medallion layers and snapshots
- [dbt-snowflake-simple-usecase](dbt-snowflake-simple-usecase): dbt Cloud on Snowflake
---

 
Copyright (c) 2026 [mkruby009]. All rights reserved.

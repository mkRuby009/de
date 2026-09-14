# Data Engineering Projects
 
Batch and OLAP workloads. Each folder is a full project with a intended Project Objective,
a setup, and a measured result.
 
Stack across the repo: PySpark, Airflow, dbt, PostgreSQL, Snowflake, Iceberg, Delta Lake, Docker.
 
| # | Project | Project Objective | Stack | Observations |
|---|---------|--------------------|-------|--------|
| [01](01-customer-insights-platform) | Customer Insights Platform | Can I run a full daily batch platform end to end, locally? | Airflow, PySpark, dbt, PostgreSQL, Docker | *fill in* |
| [02](02-lakehouse-iceberg-vs-delta) | Iceberg vs Delta Lake | Which table format handles repeated writes and OLAP scans better? | PySpark, Iceberg, Delta Lake, Parquet | *fill in* |
| [03](03-cdc-incremental-loads) | CDC and incremental loads | Which incremental load pattern costs least on the source? | PySpark, PostgreSQL | *fill in* |
| [04](04-scd2-dbt-snowflake) | SCD Type 2 | dbt snapshot or hand-written merge? | PySpark, dbt, Snowflake | *fill in* |
| [05](05-postgres-horizontal-scaling) | PostgreSQL horizontal scaling | Where does a distributed query stop scaling? | PostgreSQL, Citus, YugabyteDB, Multigres, Airflow | *fill in* |
| [06](06-spark-aqe-connect) | Spark AQE and Spark Connect | Which AQE optimisations actually fire on skewed data? | PySpark, Spark Connect | *fill in* |
 
---
 
Copyright (c) 2026 [mkruby009]. All rights reserved.

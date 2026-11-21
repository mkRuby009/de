# Spark Tuning: Job Optimization approaches

**Status:** WIP.

**Objective:** Finding job delay causes with Spark 3.0.0+ and possible fixes . One change per run, measured every time.

## Setup

- **Data:** about 1M employee rows (CSV, about 97 MB). Two departments are made heavy on purpose, about 420k rows each.
- **Cluster:** Spark 3.5.6 standalone on my laptop. 2 workers, 4 executors, 3 cores and 1.5 GB each.
- **Method:** one change per run. Each run twice; I report the second, because the first warms the cache. Numbers come from the Spark UI (Stages and SQL tabs) and `explain()`.

## Experiments

| # | Area | Question | Change tested | What I measure |
|---|---|---|---|---|
| 1 | Read | How many partitions does a file read make, and why? | `spark.sql.files.maxPartitionBytes`, `openCostInBytes`; CSV vs Parquet | Partition count, read stage time |
| 2 | Shuffle | Is the shuffle partition count right for this data? | `spark.sql.shuffle.partitions`; AQE coalescing on and off | Task count, median task time |
| 3 | Join | When does a broadcast join beat a sort-merge join? | Broadcast threshold, broadcast hint | Shuffle bytes, stage count, time |
| 4 | Skew | Why does one task run much longer than the rest? | AQE skew join settings; salting | Slowest task ÷ median task |
| 5 | Spill | Why does a task spill to disk? | Memory and cores per executor; select columns early; Parquet input | Spill (memory and disk) |

## Results

| # | Before | After | What made the difference |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

## What I learned

<!-- Only what you reproduced and can show in a screenshot or plan. -->

## Cluster notes

<!-- Executor sizing, and the JVM CPU-count setting, if you keep it. -->
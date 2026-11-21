# SCD Type 2 on Snowflake: Snapshot vs Stream vs Log

**Objective:** Build one SCD Type 2 dimension three ways, from the same source, and find which build keeps every version.

## Why this project?

`dbt snapshot` is undoubtedly smart tool to implement Slowly Changing Dimension Type 2: `dbt snapshot`.   
It works, without hassles; but I wanted to explore cases where it can fail and other approaches would be needed.

My testing goal: If a row changes twice between two pipeline runs, which build keeps both versions?

The base pipeline on Snowflake follows [a public tutorial](https://github.com/anshlambagit/Airbnb_Snowflake_DBT_Data_Engineer_Project), rebuilt but with the three-way approaches comparisons.

## What the project does

One source table holds customer records. A script applies three waves of changes. In one wave, the same customer changes twice before anything reads the table. That customer is the test case.

Three builds turn the source into a Type 2 dimension:

- **A — dbt snapshot.** Timestamp strategy. It reads the source table on each run.
- **B — Snowflake stream and MERGE.** A standard stream feeds a two-pass `MERGE`. Pass one closes the old row. Pass two inserts the new one.
- **C — Append-only change log.** Every change is a row in a log table. A `LEAD` window function turns the log into validity ranges. No `MERGE`.

A comparison model counts the versions each build kept. dbt tests hold those counts in place.

## Results

| Build | Versions kept for the test customer |
|---|---|
| A — dbt snapshot | `<your count>` |
| B — stream and MERGE | `<your count>` |
| C — change log | `<your count>` |

## Learnings

- **A snapshot reads the source as it is now.** The earlier value was already overwritten, so the middle version is gone.
- **A standard stream returns the net change since it was last read.** Two changes to the same row collapse into one. A stream is not an event log.
- **Only an append-only log keeps every version.** Nothing collapses it.
- **dbt snapshots are still the right tool for most dimensions.** They are far less work. If a dimension must record every change, for audit, you need a change feed first.

## NOTE

The change log is written by the same script that updates the source. In production, a CDC tool writes that log.

## Stack

Snowflake, dbt, SQL.
# Spark Connect: Thin Client, Remote Driver

**Objective:** Run Spark jobs from a thin client in VS Code while the driver runs on the cluster, and understand what crosses the wire between them.

## Why this project?

In classic client mode, my laptop is the driver. It plans the job, holds the results, and has to stay up. Spark Connect splits that. The client only sends a plan and gets results back. I wanted to see how much that changes in practice, and what breaks.

## Setup

| Part | What I used |
|---|---|
| Cluster | Spark 3.5.5 on Docker: master, worker and the Spark Connect server on port 15002, from [subhamkharwal/docker-images](https://github.com/subhamkharwal/docker-images) |
| Client | Python 3.12 venv with PySpark 3.5.5 and its Connect extras, matching the server |
| Editor | VS Code |

## What runs where

```text
VS Code (thin client)                      Docker cluster
  DataFrame code                             Spark Connect server (the driver)
     │                                          plans and schedules the job
     │── plan, as protobuf over gRPC ─────►     │
     │◄── results, as Arrow batches ───────     executors ◄──► executors
                                                (shuffle: Spark's own row format over Netty)
```

## Results

| Check | Result |
|---|---|
| `<job you ran>` | |
| `<what you compared>` | |

## What I learned

- **The client must match the server version.** Client and server both run 3.5.5.
- **Python 3.12 has no `distutils`.** PySpark 3.5.5 still imports it, so the client needed `setuptools`.
- **An old Spark install can shadow the venv.** A `PYTHONPATH` from a Spark download pointed at a different PySpark.
- **The client gets DataFrames and SQL only.** No RDD API and no `SparkContext`.
- **Arrow is not the shuffle format.** Arrow carries results to the client. Executors shuffle Spark's own row format over Netty.

## How this maps to production

One long-running Spark server, many thin clients: notebooks, IDEs and apps, with no local Spark install. Databricks Connect is built on Spark Connect.
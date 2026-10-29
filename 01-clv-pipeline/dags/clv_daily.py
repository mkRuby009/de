import os
import shutil
import sys
from pathlib import Path

import pendulum
from airflow.sdk import dag, task
from airflow.providers.standard.operators.bash import BashOperator

REPO_ROOT = Path(__file__).resolve().parents[1]
DBT_PROJECT_DIR = REPO_ROOT / "clv_project"
DATA_DIR = Path(os.environ.get("CLV_DATA_DIR", REPO_ROOT / "data"))
PROD_DB = DATA_DIR / "prod.duckdb"

DBT_BIN = shutil.which("dbt", path=str(Path(sys.executable).parent)) or "dbt"

DBT_ENV = {
    "DBT_PROFILES_DIR": str(DBT_PROJECT_DIR),
    "CLV_DATA_DIR": str(DATA_DIR),
    # keep Airflow's manifest and run results apart from the ones VS Code writes
    "DBT_TARGET_PATH": "target/airflow",
    # plain text in the task log instead of ANSI colour codes
    "DBT_USE_COLORS": "false",
}

DOC_MD = """
Builds the `clv_project` dbt project against `data/prod.duckdb`, then logs
the top 10 customers by predicted customer lifetime value (CLV).

* `dbt_build` runs `dbt build --target prod`: seeds, models and tests in
  dependency order. A failing test fails the task and the report is skipped.
* `top_customers` reads `dim_customers` read-only and returns the rows as XCom.
"""

@dag(
    dag_id = "clv_daily",
    schedule= "@daily",
    start_date= pendulum.datetime(2026,1,1, tz="UTC"),
    catchup= False,
    #one writer for DuckDB, so runs do not overlap
    max_active_runs= 1,
    default_args={
        "retries": 0,
        "retry_delay": pendulum.duration(minutes=5)
    },
    doc_md = DOC_MD
)
def clv_daily():
    # Bash task to build models, seeds, tests in dbt project
    @task.bash(
        cwd= str(DBT_PROJECT_DIR),
        env = DBT_ENV,
        append_env=True
    )
    def dbt_build():
        return f"{DBT_BIN} build --target prod"

    # python task to query top 10 customers ordered by their predicted CLV
    @task
    def top_customers(limit: int = 10)-> list[dict]:
        import duckdb

        query = """
            select customer_id, first_name, last_name, 
                   net_orders, net_revenue, predicted_clv_project
            from main.dim_customers
            order by predicted_clv_project desc, customer_id
            fetch first ? rows only
        """

        with duckdb.connect(PROD_DB) as con:
            rows = con.execute(query, [limit]).fetchall()

        result = [
            {
                "customer_id": customer_id,
                "name": f"{first_name} {last_name}",
                "net_orders": net_orders,
                "net_revenue": float(net_revenue),
                "predicted_clv_project": float(predicted_clv_project),
            }
            for customer_id, first_name, last_name, net_orders, net_revenue, predicted_clv_project in rows
        ]
        for rank, row in enumerate(result, start=1):
            print(
                f"{rank:>2}. {row['name']:<20} revenue ${row['net_revenue']:>7.2f}"
                f"  CLV ${row['predicted_clv_project']:>8.2f}"
            )
        return result

    dbt_build() >> top_customers()

pipeline = clv_daily()

if __name__ == "__main__":
    pipeline.test()
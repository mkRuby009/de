# Same variables as .vscode/settings.json, for shells outside VS Code:
#
#   source scripts/env.sh

_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

export DBT_PROFILES_DIR="$_root/customer_ltv"
export LTV_DATA_DIR="$_root/data"

export AIRFLOW_HOME="$_root/.airflow"
export AIRFLOW__CORE__DAGS_FOLDER="$_root/dags"
export AIRFLOW__CORE__LOAD_EXAMPLES=False
export AIRFLOW__API__HOST=127.0.0.1
export AIRFLOW__DAG_PROCESSOR__REFRESH_INTERVAL=30

unset _root
"""
Earthquake Pipeline DAG

Daily ELT pipeline:
  1. fetch_and_load  — calls USGS API for the execution interval, upserts into raw.earthquakes
  2. dbt_run         — runs all dbt models (staging → intermediate → marts)
  3. dbt_test        — runs all dbt data quality tests; fails the DAG if any test fails

Schedule: @daily (runs at midnight UTC for the previous day's data)
Backfill: disabled (catchup=False) — trigger manually via the Airflow UI to backfill
"""
import sys
from datetime import datetime, timedelta

from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator

sys.path.insert(0, "/opt/airflow/scripts")

DBT_DIR = "/opt/airflow/earthquake_dbt"
DBT_PROFILES_DIR = "/opt/airflow/earthquake_dbt"

DEFAULT_ARGS = {
    "owner": "airflow",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}


@dag(
    dag_id="earthquake_pipeline",
    description="Daily USGS earthquake ELT: fetch → load → dbt run → dbt test",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["earthquakes", "usgs", "dbt", "portfolio"],
)
def earthquake_pipeline():

    @task
    def fetch_and_load(data_interval_start=None, data_interval_end=None) -> int:
        """
        Fetch earthquakes from USGS for the Airflow execution interval and upsert
        into raw.earthquakes.

        Airflow injects data_interval_start / data_interval_end automatically when
        they are declared as task parameters — this is the idiomatic way to make
        a task aware of its scheduling window.
        """
        import logging
        from fetch_earthquakes import run

        start = data_interval_start.strftime("%Y-%m-%dT%H:%M:%S")
        end = data_interval_end.strftime("%Y-%m-%dT%H:%M:%S")

        logging.info("Processing interval %s → %s", start, end)
        return run(start, end)

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=(
            f"cd {DBT_DIR} && "
            f"dbt run --profiles-dir {DBT_PROFILES_DIR} --target dev"
        ),
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=(
            f"cd {DBT_DIR} && "
            f"dbt test --profiles-dir {DBT_PROFILES_DIR} --target dev"
        ),
    )

    fetch_and_load() >> dbt_run >> dbt_test


earthquake_pipeline()

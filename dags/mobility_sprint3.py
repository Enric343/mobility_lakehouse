"""Run sample-week ELT through the two Gold analyses and their maps."""

from datetime import datetime, timezone
from pathlib import Path
import subprocess
import sys

from airflow.sdk import dag, task


ROOT = Path(__file__).resolve().parents[1]


def run_script(script):
    subprocess.run([sys.executable, str(ROOT / "scripts" / script)], cwd=ROOT, check=True)


@dag(
    dag_id="mobility_sprint3",
    schedule=None,
    start_date=datetime(2023, 3, 6, tzinfo=timezone.utc),
    catchup=False,
    max_active_runs=1,
    tags=["mobility", "ducklake"],
)
def mobility_sprint3():
    @task
    def download_inputs():
        run_script("download_data.py")

    @task
    def load_bronze_and_silver():
        run_script("run_sprint2.py")

    @task
    def build_validated_gold():
        run_script("build_gold.py")

    @task
    def publish_report():
        run_script("render_sprint3.py")

    download_inputs() >> load_bronze_and_silver() >> build_validated_gold() >> publish_report()


dag = mobility_sprint3()

# Local runbook

Run commands from the repository root. For storage, lineage and where each table
is built, see the [lakehouse map](lakehouse.md) and the [Bronze to Silver guide](bronze-to-silver.md).

## Run Sprint 3

Use Linux or Ubuntu in WSL2 with Python 3.12 and `venv` for Airflow. Run these
commands from the repository root inside that environment.

```bash
python3 -m venv .venv/airflow
source .venv/airflow/bin/activate
python -m pip install -r requirements-airflow.txt \
  --constraint https://raw.githubusercontent.com/apache/airflow/constraints-3.2.1/constraints-3.12.txt
python -m pip install -r requirements-sprint3.txt
export AIRFLOW_HOME="$HOME/.local/share/mobility-airflow"
export AIRFLOW__CORE__DAGS_FOLDER="$PWD/dags"
export AIRFLOW__CORE__LOAD_EXAMPLES=False
airflow db migrate
airflow dags test mobility_sprint3 2023-03-12
```

The DAG downloads inputs, loads Bronze and Silver, builds and validates Gold,
and publishes the report. It uses the existing sample week
(6–12 March 2023). The Airflow argument is the logical run date. The DAG is manual
and allows one active run for the local catalog. The source and Gold load records
let repeated runs reuse validated data. The Airflow database and logs stay under
`AIRFLOW_HOME`. [Airflow installation and Windows support](https://airflow.apache.org/docs/apache-airflow/3.2.1/installation/prerequisites.html)

For direct execution against the existing Silver data, run these commands in a
Python environment on Windows or Linux.

```shell
python -m pip install -r requirements-sprint3.txt
python scripts/build_gold.py
python scripts/render_sprint3.py
```

Open `data/reports/sprint3/index.html` for the analysis. The folder also contains
two PNG maps and two analytical plots. `scripts/build_gold.py --rebuild` replaces
the sample's Gold snapshot after a model change. Run the report command again to
publish the updated figures. [Gold metrics and interpretation](sprint3.md)

## Load Bronze and Silver separately

From the repository root, using a Python environment with `pip`:

```shell
python -m pip install -r requirements.txt
python scripts/download_data.py
python scripts/run_sprint2.py
```

The default window is 2023-03-06 through 2023-03-12 at district, municipality
and GAU levels. Downloads are cached under `data/raw/`. The catalog and Parquet
files are stored in `data/lakehouse/`. Both commands accept inclusive dates.
For a smaller development run, pass one date to `scripts/run_sprint2.py`.
Pass `--allow-missing-days` to list missing mobility files and continue loading
available ones. Use `--lake-dir` to create a separate local catalog.

## Query the local lakehouse

To inspect the local catalog from a Python session in the repository root:

```python
from pathlib import Path
import duckdb
from duckdb_core_ext_ducklake import get_extension_load_path

with duckdb.connect() as conn:
    conn.load_extension(get_extension_load_path())
    catalog = Path("data/lakehouse/catalog.ducklake").resolve().as_posix().replace("'", "''")
    warehouse = Path("data/lakehouse/warehouse").resolve().as_posix().replace("'", "''")
    conn.execute(f"ATTACH 'ducklake:{catalog}' AS lake (DATA_PATH '{warehouse}/', OVERRIDE_DATA_PATH true, READ_ONLY)")
    conn.sql("SELECT * FROM lake.main.mobility_loads ORDER BY observation_date, zone_level, dataset LIMIT 10").show()
```

Run `python scripts/run_sprint1.py` to exercise the original two Gold examples
in a disposable DuckDB session.

The same connection can run the SQL examples in the [table catalog](tables/README.md).

## Notebooks

Run notebooks with `notebooks/` as the working directory. The exploration needs
Jupyter, pandas, DuckDB's `spatial` extension and the downloaded INE
province list described in the source inventory. It retains the source analysis,
zone matching, socioeconomic metrics, and holiday experiments.

The Silver schema notebook resets the seven Silver tables in
`data/lakehouse.duckdb`. Use it with a disposable local database.

"""Run the two sample-week transformations in a disposable DuckDB session."""

import argparse
import csv
from pathlib import Path
from tempfile import TemporaryDirectory

import duckdb
import shapefile

from lakehouse.sources import (
    RAW, SAMPLE_END, SAMPLE_START, daily_mitma_path, days_inclusive, zone_geometry_path, zone_names_path,
)

ROOT = Path(__file__).resolve().parents[1]
TRIP_LEVEL = "municipios"
OVERNIGHT_LEVEL = "distritos"


def load_zone_keys(connection, catalogs):
    connection.execute("""
        CREATE TEMP TABLE sample_zone_keys (
            zone_level VARCHAR,
            zone_id VARCHAR CHECK (trim(zone_id) <> ''),
            PRIMARY KEY (zone_level, zone_id)
        )
    """)
    for level, (names, centroids) in catalogs.items():
        with names.open(encoding="utf-8-sig", newline="") as handle:
            ids = [row["ID"] for row in csv.DictReader(handle, delimiter="|")]
        # Foreign zones exist only in the shapefiles. The DBF contains their IDs.
        with shapefile.Reader(dbf=str(centroids), encoding="utf-8") as reader:
            ids.extend(row["ID"] for row in reader.iterRecords() if row["ID"].startswith(("FR", "PT")))
        ids.append("externo")
        connection.executemany("INSERT INTO sample_zone_keys VALUES (?, ?)", [(level, key) for key in ids])


def create_bronze_views(connection, trip_files, overnight_files):
    connection.execute("SET VARIABLE trip_files = ?", [[path.as_posix() for path in trip_files]])
    connection.execute("SET VARIABLE overnight_files = ?", [[path.as_posix() for path in overnight_files]])
    connection.execute("SET VARIABLE trip_level = ?", [TRIP_LEVEL])
    connection.execute("SET VARIABLE overnight_level = ?", [OVERNIGHT_LEVEL])
    connection.execute("""
        CREATE TEMP VIEW bronze_mitma_od_daily AS
        SELECT * EXCLUDE (filename), getvariable('trip_level') AS zone_level, filename AS _source_file
        FROM read_csv(getvariable('trip_files'), delim='|', header=true, all_varchar=true, filename=true);

        CREATE TEMP VIEW bronze_mitma_overnight_daily AS
        SELECT * EXCLUDE (filename), getvariable('overnight_level') AS zone_level, filename AS _source_file
        FROM read_csv(getvariable('overnight_files'), delim='|', header=true, all_varchar=true, filename=true);
    """)


def run(raw_dir):
    mitma = raw_dir / "mitma"
    days = list(days_inclusive(SAMPLE_START, SAMPLE_END))
    trips = [mitma / daily_mitma_path(day, TRIP_LEVEL, "viajes") for day in days]
    overnight = [mitma / daily_mitma_path(day, OVERNIGHT_LEVEL, "pernoctaciones") for day in days]
    catalogs = {
        level: (mitma / zone_names_path(level), mitma / zone_geometry_path(level, "dbf", centroid=True))
        for level in (TRIP_LEVEL, OVERNIGHT_LEVEL)
    }
    inputs = trips + overnight + [path for files in catalogs.values() for path in files]
    missing = [str(path) for path in inputs if not path.is_file()]
    if missing:
        raise FileNotFoundError("Missing sample files. See docs/data_sources.md.\n" + "\n".join(missing))

    print(f"Sprint 1 sample: {SAMPLE_START} to {SAMPLE_END}", flush=True)
    with TemporaryDirectory(prefix="mobility-sprint1-") as scratch:
        config = {"threads": 4, "memory_limit": "4GB", "temp_directory": Path(scratch).as_posix()}
        with duckdb.connect(config=config) as connection:
            connection.execute("SET VARIABLE sample_start = ?", [SAMPLE_START])
            connection.execute("SET VARIABLE sample_end = ?", [SAMPLE_END])
            create_bronze_views(connection, trips, overnight)
            load_zone_keys(connection, catalogs)

            for fact, source in (("trips", "od"), ("overnight", "overnight")):
                relative_path = f"bronze_to_silver/fact_{fact}.sql"
                print(f"Running {relative_path}", flush=True)
                query = (ROOT / "sql" / relative_path).read_text(encoding="utf-8")
                connection.execute(
                    f"CREATE TABLE silver_fact_{fact} AS {query}",
                    {"source_table": f"bronze_mitma_{source}_daily"},
                )

            print("Running silver_to_gold/typical_day.sql", flush=True)
            gold_sql = ROOT / "sql/silver_to_gold"
            connection.execute("SET VARIABLE gold_start = ?", [SAMPLE_START])
            connection.execute("SET VARIABLE gold_end = ?", [SAMPLE_END])
            query = (gold_sql / "daily_od.sql").read_text(encoding="utf-8")
            connection.execute(f"CREATE TEMP TABLE daily_od AS {query}", {
                "source_table": "silver_fact_trips", "level": TRIP_LEVEL,
            })
            connection.execute((gold_sql / "day_type.sql").read_text(encoding="utf-8"))
            connection.execute("""
                CREATE TEMP VIEW patterned_od AS
                SELECT *, 'calendar' AS pattern_basis, mobility_day_type(date, false) AS day_type FROM daily_od
            """)
            query = (gold_sql / "typical_day.sql").read_text(encoding="utf-8").strip().removesuffix(";")
            connection.execute(f"CREATE TABLE gold_typical_day_patterns AS SELECT * EXCLUDE (pattern_basis) FROM ({query})")
            print("Running silver_to_gold/overnight_presence.sql", flush=True)
            connection.execute((gold_sql / "overnight_presence.sql").read_text(encoding="utf-8"))

            print("Running validation/sprint1.sql", flush=True)
            checks = (ROOT / "sql/validation/sprint1.sql").read_text(encoding="utf-8")
            results = connection.execute(checks).fetchall()
            for name, failures in results:
                print(f"{'FAIL' if failures else 'PASS'} {name} ({failures} issues)")
            if any(failures for _, failures in results):
                return 1

            print()
            connection.sql("""
                SELECT 'silver_fact_trips' AS table_name, count(*) AS rows FROM silver_fact_trips
                UNION ALL SELECT 'silver_fact_overnight', count(*) FROM silver_fact_overnight
                UNION ALL SELECT 'gold_typical_day_patterns', count(*) FROM gold_typical_day_patterns
                UNION ALL SELECT 'gold_overnight_presence', count(*) FROM gold_overnight_presence
            """).show()
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw-dir", type=Path, default=RAW, help="Source directory")
    args = parser.parse_args()
    try:
        return run(args.raw_dir.resolve())
    except (duckdb.Error, OSError, shapefile.ShapefileException) as error:
        parser.exit(1, f"Sprint 1 failed: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())

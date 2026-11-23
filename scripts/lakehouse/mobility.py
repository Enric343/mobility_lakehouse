"""Load, check, and commit daily MITMA facts by dataset, zoning level, and date."""

from dataclasses import dataclass
from datetime import date
from math import isclose

from .catalog import read_sql, transaction
from .sources import DAILY_DATASETS, ZONE_NAMES, daily_mitma_path, days_inclusive
from .validation import QualityError


@dataclass(frozen=True)
class MobilityFile:
    dataset: str
    level: str
    day: date

    @property
    def source(self):
        return f"mitma/{daily_mitma_path(self.day, self.level, self.dataset)}"


# Dataset-specific table names and measures used to run the same batch steps.
FACTS = {
    "viajes": ("od", "trips", "trips"),
    "pernoctaciones": ("overnight", "overnight", "people"),
}


def pending_files(connection, raw_dir, start, end, allow_missing):
    loaded = set(connection.execute("""
        SELECT dataset, zone_level, observation_date FROM lake.main.mobility_loads
        WHERE observation_date BETWEEN ? AND ?
    """, [start, end]).fetchall())
    pending = [
        MobilityFile(dataset, level, day)
        for day in days_inclusive(start, end) for level in ZONE_NAMES for dataset in DAILY_DATASETS
        if (dataset, level, day) not in loaded
    ]
    missing = {batch for batch in pending if not (raw_dir / batch.source).is_file()}
    if missing:
        paths = "\n".join(batch.source for batch in pending if batch in missing)
        if not allow_missing:
            raise FileNotFoundError(f"Missing {len(missing)} mobility files in {raw_dir}:\n{paths}")
        print(f"Leaving {len(missing)} unavailable inputs pending:\n{paths}", flush=True)
    available = [batch for batch in pending if batch not in missing]
    print(f"Mobility window {start} through {end}: {len(available)} pending, {len(loaded)} already loaded", flush=True)
    return available


def load_day(connection, raw_dir, batch):
    bronze_suffix, fact, measure = FACTS[batch.dataset]
    bronze = f"lake.main.bronze_mitma_{bronze_suffix}_daily"
    silver = f"lake.main.silver_fact_{fact}"
    print(f"Loading {batch.day} {batch.level} {batch.dataset}", flush=True)
    connection.execute(read_sql("ingestion/mobility_day.sql"), {
        "level": batch.level,
        "source_file": batch.source,
        "path": (raw_dir / batch.source).as_posix(),
    })
    source_columns = {column[0] for column in connection.sql("DESCRIBE daily_bronze").fetchall()}
    target_columns = {column[0] for column in connection.sql(f"DESCRIBE {bronze}").fetchall()}
    if source_columns != target_columns:
        raise QualityError(f"Unexpected columns in {batch.source}: missing {target_columns - source_columns}, extra {source_columns - target_columns}")

    rows, total, invalid, duplicates, unknown_zones = connection.execute(
        read_sql(f"validation/bronze_{fact}.sql"), {"level": batch.level, "day": batch.day.strftime("%Y%m%d")},
    ).fetchone()
    if rows == 0 or invalid or duplicates or unknown_zones:
        raise QualityError(f"Invalid Bronze {batch.source}: {rows:,} rows, {invalid:,} invalid, "
                           f"{duplicates:,} duplicate keys, {unknown_zones:,} unknown zone IDs")

    query = read_sql(f"bronze_to_silver/fact_{fact}.sql")
    connection.execute(f"CREATE TEMP TABLE daily_silver AS {query}", {"source_table": "daily_bronze"})
    silver_rows, silver_total = connection.sql(f"SELECT count(*), sum({measure}) FROM daily_silver").fetchone()
    wrong_count = silver_rows == 0 or silver_rows > rows or (fact == "overnight" and silver_rows != rows)
    if wrong_count or silver_total is None or not isclose(total, silver_total, rel_tol=1e-10, abs_tol=0.001):
        raise QualityError(f"Silver row counts or totals failed for {batch.source}: {rows:,}/{silver_rows:,} rows, {total}/{silver_total} total")

    with transaction(connection):
        connection.execute(f"INSERT INTO {bronze} BY NAME SELECT * FROM daily_bronze")
        connection.execute(f"INSERT INTO {silver} BY NAME SELECT * FROM daily_silver")
        connection.execute("INSERT INTO lake.main.mobility_loads VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp)", [
            batch.dataset, batch.level, batch.day, batch.source, rows, silver_rows, total,
        ])
    connection.execute("DROP TABLE daily_silver; DROP TABLE daily_bronze")
    print(f"Committed {rows:,} Bronze rows and {silver_rows:,} Silver rows, total {total:,.3f}", flush=True)

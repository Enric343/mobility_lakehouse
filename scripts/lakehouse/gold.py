"""Publish a validated Gold snapshot from the Silver tables for one sample window."""

from .catalog import read_sql, transaction
from .clustering import label_daily_profiles
from .sources import ZONE_NAMES, days_inclusive
from .validation import QualityError, require_checks


MODEL_REVISION = "sprint3-v1"
RESULT_TABLES = (
    "gold_typical_day_patterns", "gold_day_assignments", "gold_hourly_demand", "gold_origin_demand",
    "gold_infrastructure_gaps", "gold_gravity_zone_ranking", "gold_gravity_calibration",
)


def _gold_sql(path):
    return read_sql(f"silver_to_gold/{path}.sql").strip().removesuffix(";")


def _publish(connection, table, query):
    connection.execute(f"""
        INSERT INTO lake.main.{table} BY NAME
        SELECT getvariable('gold_start') AS period_start, getvariable('gold_end') AS period_end, results.*
        FROM ({query}) results
    """)


def _typical_day(connection, dates):
    connection.execute(_gold_sql("day_type"))
    for level in ZONE_NAMES:
        print(f"Aggregating daily OD and typical-day demand for {level}", flush=True)
        connection.execute("SET VARIABLE gold_level = ?", [level])
        connection.execute(f"CREATE OR REPLACE TEMP TABLE daily_od AS {_gold_sql('daily_od')}", {
            "source_table": "lake.main.silver_fact_trips", "level": level,
        })
        connection.execute(_gold_sql("classify_origins"))
        connection.execute(_gold_sql("daily_profiles"))
        label_daily_profiles(connection, dates)
        connection.execute("CREATE TEMP VIEW patterned_od AS SELECT *, 'calendar' AS pattern_basis FROM classified_od")
        _publish(connection, "gold_typical_day_patterns", _gold_sql("typical_day"))
        connection.execute(_gold_sql("classify_clusters"))
        _publish(connection, "gold_typical_day_patterns", _gold_sql("typical_day"))
        _publish(connection, "gold_day_assignments", "SELECT * FROM daily_labels")
        _publish(connection, "gold_hourly_demand", _gold_sql("hourly_demand"))
        _publish(connection, "gold_origin_demand", _gold_sql("origin_demand"))
        if level == "municipios":
            connection.execute("""
                CREATE TEMP TABLE municipal_actual AS
                SELECT origin_zone_id, destination_zone_id, sum(trips) AS actual_trips
                FROM daily_od WHERE origin_zone_id <> destination_zone_id
                GROUP BY origin_zone_id, destination_zone_id
            """)
        connection.execute("DROP VIEW patterned_od; DROP VIEW classified_od; DROP TABLE daily_od")


def _gravity_model(connection):
    print("Estimating municipal demand and ranking comparable origin volumes", flush=True)
    connection.execute(_gold_sql("gravity_candidates"))
    connection.execute(_gold_sql("gravity_calibration"))
    _publish(connection, "gold_gravity_calibration", "SELECT * FROM gravity_fit")
    _publish(connection, "gold_infrastructure_gaps", _gold_sql("infrastructure_gaps"))
    _publish(connection, "gold_gravity_zone_ranking", _gold_sql("gravity_zone_ranking"))


def build_gold(connection, start, end, *, rebuild=False):
    dates = list(days_inclusive(start, end))
    expected = {(level, day) for level in ZONE_NAMES for day in dates}
    connection.execute("SET VARIABLE gold_start = ?", [start])
    connection.execute("SET VARIABLE gold_end = ?", [end])
    with transaction(connection):
        loaded = connection.execute("""
            SELECT zone_level, observation_date FROM lake.main.mobility_loads
            WHERE dataset = 'viajes' AND observation_date BETWEEN ? AND ?
        """, [start, end]).fetchall()
        if len(loaded) != len(expected) or set(loaded) != expected:
            raise QualityError("Gold requires exactly one Silver trip load for every sample day and zoning level")

        connection.execute(read_sql("schema/gold.sql"))
        previous = connection.execute("""
            SELECT model_revision FROM lake.main.gold_runs WHERE period_start = ? AND period_end = ?
        """, [start, end]).fetchall()
        if previous == [(MODEL_REVISION,)] and not rebuild:
            require_checks(connection, "gold.sql")
            print(f"Validated Gold already published for {start} through {end}", flush=True)
            return

        for table in (*RESULT_TABLES, "gold_runs"):
            connection.execute(f"DELETE FROM lake.main.{table} WHERE period_start = ? AND period_end = ?", [start, end])
        _typical_day(connection, dates)
        _gravity_model(connection)
        require_checks(connection, "gold.sql")
        connection.execute("INSERT INTO lake.main.gold_runs VALUES (?, ?, ?, current_timestamp)", [start, end, MODEL_REVISION])
    print(f"Gold committed for {start} through {end}", flush=True)

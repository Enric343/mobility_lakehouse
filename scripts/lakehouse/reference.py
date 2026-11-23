"""Load and validate the fixed 2023 geography, socioeconomic data, and holidays."""

from xml.etree import ElementTree

from .catalog import read_sql, transaction
from .sources import (
    BOE_HOLIDAYS, INE_ADRH, INE_DIRCE, INE_PROVINCES, SHAPE_EXTENSIONS, ZONE_MAPPING, ZONE_NAMES,
    zone_geometry_path, zone_names_path,
)
from .validation import require_checks


def boe_rows(path):
    xml = ElementTree.parse(path).getroot()
    table = xml.find(".//table")
    if table is None:
        raise ValueError(f"Holiday table missing from {path}")
    rows = [[" ".join("".join(cell.itertext()).split()) for cell in row] for row in table.iter("tr")]
    if len(rows) < 3 or len(rows[1]) != 19:
        raise ValueError(f"Expected holiday rows and 19 region columns in {path}")
    regions = rows[1]
    year = path.name.split("_", 1)[0]
    month = None
    for label, *marks in rows[2:]:
        if len(marks) != len(regions):
            raise ValueError(f"Unexpected number of region columns for {label} in {path}")
        if not any(marks):
            month = label
        else:
            yield from ((year, month, label, region, mark) for region, mark in zip(regions, marks))


def load_reference(connection, raw_dir):
    if connection.sql("SELECT count(*) FROM lake.main.reference_load WHERE reference_year = 2023").fetchone()[0]:
        print("2023 reference tables already loaded", flush=True)
        return

    zones = [f"mitma/{zone_names_path(level)}" for level in ZONE_NAMES]
    shape_parts = [
        f"mitma/{zone_geometry_path(level, ext, centroid=centroid)}"
        for level in ZONE_NAMES for centroid in (False, True) for ext in SHAPE_EXTENSIONS
    ]
    adrh = list(INE_ADRH.values())
    mapping = f"mitma/{ZONE_MAPPING}"
    files = [*zones, *shape_parts, *adrh, mapping, INE_DIRCE, INE_PROVINCES, BOE_HOLIDAYS]
    missing = [file for file in files if not (raw_dir / file).is_file()]
    if missing:
        raise FileNotFoundError(f"Missing reference files in {raw_dir}. Run scripts/download_data.py.\n" + "\n".join(missing))

    # Shape and CSV paths are absolute for reading. Row lineage is relative to raw_dir.
    path_vars = {
        "raw_dir": raw_dir.as_posix(),
        "zone_names": [(raw_dir / name).as_posix() for name in zones],
        "zone_mapping_path": (raw_dir / mapping).as_posix(), "zone_mapping_source": mapping,
        "adrh_paths": [(raw_dir / name).as_posix() for name in adrh],
        "dirce_path": (raw_dir / INE_DIRCE).as_posix(), "dirce_source": INE_DIRCE,
        "provincial_path": (raw_dir / INE_PROVINCES).as_posix(), "provincial_source": INE_PROVINCES,
    }
    for name, value in path_vars.items():
        connection.execute(f"SET VARIABLE {name} = ?", [value])
    connection.execute("CREATE TEMP TABLE boe_rows (year VARCHAR, mes VARCHAR, fiesta VARCHAR, ccaa VARCHAR, marca VARCHAR)")
    connection.executemany("INSERT INTO boe_rows VALUES (?, ?, ?, ?, ?)", list(boe_rows(raw_dir / BOE_HOLIDAYS)))

    with transaction(connection):
        print("Loading Bronze reference tables (MITMA, INE, BOE)", flush=True)
        connection.execute(read_sql("ingestion/mitma_reference.sql"))
        geometry_query = read_sql("ingestion/mitma_geometry.sql")
        for level in ZONE_NAMES:
            for kind in ("polygon", "centroid"):
                source = f"mitma/{zone_geometry_path(level, 'shp', centroid=kind == 'centroid')}"
                connection.execute(geometry_query, {
                    "level": level, "kind": kind, "source_file": source, "path": (raw_dir / source).as_posix(),
                })
        connection.execute(read_sql("ingestion/ine.sql"))
        connection.execute("""
            INSERT INTO lake.main.bronze_boe_holidays BY NAME
            SELECT *, ? AS _source_file, current_timestamp AS _ingested_at FROM boe_rows
        """, [BOE_HOLIDAYS])
        require_checks(connection, "reference_bronze.sql")

        print("Building Silver dimensions, holidays and 2023 zone metrics", flush=True)
        for name in ("dimensions.sql", "holidays.sql", "section_mapping.sql", "zone_metrics.sql"):
            connection.execute(read_sql(f"bronze_to_silver/{name}"))
        require_checks(connection, "reference_silver.sql")
        connection.execute("INSERT INTO lake.main.reference_load VALUES (2023, current_timestamp)")
    print("2023 reference tables committed", flush=True)

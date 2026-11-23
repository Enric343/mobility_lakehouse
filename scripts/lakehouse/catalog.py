"""Open the local DuckLake catalog and initialize its table contracts."""

from contextlib import contextmanager

import duckdb
from duckdb_core_ext_ducklake import get_extensions_dir

from .sources import ROOT


def read_sql(path):
    return (ROOT / "sql" / path).read_text(encoding="utf-8")


@contextmanager
def connect_lake(directory, *, read_only=False, create=False, scratch_directory=None):
    catalog_path = directory / "catalog.ducklake"
    if create:
        directory.mkdir(parents=True, exist_ok=True)
    elif not catalog_path.is_file():
        raise FileNotFoundError(f"DuckLake catalog missing: {catalog_path}. Run Sprint 2 first.")
    config = {
        "threads": 4,
        "memory_limit": "4GB",
        "preserve_insertion_order": False,
        "extension_directory": get_extensions_dir(),
        "temp_directory": (scratch_directory or directory / "scratch").as_posix(),
    }
    with duckdb.connect(config=config) as connection:
        connection.load_extension("ducklake")
        connection.load_extension("spatial")
        connection.execute("SET geometry_always_xy = true")
        catalog = catalog_path.as_posix().replace("'", "''")
        warehouse = (directory / "warehouse").as_posix().replace("'", "''")
        options = f"DATA_PATH '{warehouse}/', OVERRIDE_DATA_PATH true, DATA_INLINING_ROW_LIMIT 0"
        if read_only:
            options += ", READ_ONLY"
        connection.execute(f"ATTACH 'ducklake:{catalog}' AS lake ({options})")
        yield connection


@contextmanager
def open_catalog(directory):
    with connect_lake(directory, create=True) as connection:
        connection.execute("CREATE SCHEMA silver_contract")
        connection.execute("SET schema = 'silver_contract'")
        connection.execute(read_sql("schema/silver.sql"))
        connection.execute("SET schema = 'main'")
        with transaction(connection):
            connection.execute(read_sql("schema/bronze.sql"))
            connection.execute(read_sql("schema/ducklake.sql"))
        yield connection


@contextmanager
def transaction(connection):
    connection.execute("BEGIN TRANSACTION")
    try:
        yield
    except BaseException:
        connection.execute("ROLLBACK")
        raise
    else:
        connection.execute("COMMIT")

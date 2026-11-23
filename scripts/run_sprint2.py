"""Load and validate Bronze and initial Silver tables in a local DuckLake."""

import argparse
from datetime import date
from pathlib import Path
from xml.etree.ElementTree import ParseError

import duckdb

from lakehouse.catalog import open_catalog
from lakehouse.mobility import load_day, pending_files
from lakehouse.reference import load_reference
from lakehouse.sources import RAW, ROOT, SAMPLE_END, SAMPLE_START


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("start", nargs="?", type=date.fromisoformat)
    parser.add_argument("end", nargs="?", type=date.fromisoformat, help="Inclusive end date")
    parser.add_argument("--raw-dir", type=Path, default=RAW, help="Directory of original input files")
    parser.add_argument("--lake-dir", type=Path, default=ROOT / "data/lakehouse", help="Directory for the catalog and Parquet files")
    parser.add_argument("--allow-missing-days", action="store_true", help="Report missing mobility files and load available partitions")
    args = parser.parse_args()
    start = args.start or SAMPLE_START
    end = args.end or args.start or SAMPLE_END
    if end < start:
        parser.error("end must be on or after start")
    raw_dir, lake_dir = args.raw_dir.resolve(), args.lake_dir.resolve()
    if lake_dir.is_relative_to(raw_dir):
        parser.error("--lake-dir must be outside the raw inputs directory")

    try:
        with open_catalog(lake_dir) as connection:
            pending = pending_files(connection, raw_dir, start, end, args.allow_missing_days)
            load_reference(connection, raw_dir)
            for batch in pending:
                load_day(connection, raw_dir, batch)
    except (duckdb.Error, OSError, ValueError, ParseError) as error:
        parser.exit(1, f"Sprint 2 failed: {error}\n")

    print(f"DuckLake ready at {lake_dir}")


if __name__ == "__main__":
    main()

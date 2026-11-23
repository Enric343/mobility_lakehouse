"""Build the two Sprint 3 Gold analyses for the existing sample week."""

import argparse
from pathlib import Path
from tempfile import TemporaryDirectory

import duckdb

from lakehouse.catalog import connect_lake
from lakehouse.gold import build_gold
from lakehouse.sources import ROOT, SAMPLE_END, SAMPLE_START


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lake-dir", type=Path, default=ROOT / "data/lakehouse")
    parser.add_argument("--rebuild", action="store_true", help="Recompute the sample after changing analysis rules")
    args = parser.parse_args()
    try:
        with TemporaryDirectory(prefix="mobility-gold-") as scratch:
            with connect_lake(args.lake_dir.resolve(), scratch_directory=Path(scratch)) as connection:
                build_gold(connection, SAMPLE_START, SAMPLE_END, rebuild=args.rebuild)
    except (duckdb.Error, OSError, ValueError) as error:
        parser.exit(1, f"Gold build failed: {error}\n")


if __name__ == "__main__":
    main()

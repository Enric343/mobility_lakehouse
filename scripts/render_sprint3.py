"""Publish the sample-week report and figures from validated Gold tables."""

import argparse
import os
from pathlib import Path
from tempfile import TemporaryDirectory

import duckdb

from lakehouse.catalog import connect_lake, transaction
from lakehouse.sources import ROOT, SAMPLE_END, SAMPLE_START


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lake-dir", type=Path, default=ROOT / "data/lakehouse")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "data/reports/sprint3")
    args = parser.parse_args()
    try:
        with TemporaryDirectory(prefix="mobility-matplotlib-") as scratch:
            os.environ.setdefault("MPLCONFIGDIR", scratch)
            from reporting.sprint3 import publish_report

            with connect_lake(args.lake_dir.resolve(), read_only=True) as connection:
                with transaction(connection):
                    report = publish_report(connection, args.output_dir.resolve(), SAMPLE_START, SAMPLE_END)
    except (duckdb.Error, OSError, ValueError) as error:
        parser.exit(1, f"Sprint 3 report failed: {error}\n")
    print(f"Report ready at {report}")


if __name__ == "__main__":
    main()

"""Download the mobility window and the reference inputs into data/raw."""

import argparse
import shutil
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path
from tempfile import NamedTemporaryFile
from urllib.parse import quote

from lakehouse.sources import (
    BOE_HOLIDAYS, DAILY_DATASETS, INE_ADRH, INE_DIRCE, INE_PROVINCES, INE_PROVINCES_URL,
    RAW, SAMPLE_END, SAMPLE_START, SHAPE_EXTENSIONS, ZONE_MAPPING, ZONE_NAMES,
    daily_mitma_path, days_inclusive, write_ine_provinces, zone_geometry_path, zone_names_path,
)

MITMA = "https://movilidad-opendata.mitma.es/"
INE = "https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/"


def get(path, url=None, *, province_table=False, allow_missing=False):
    dest = RAW / ("mitma/" + path if url is None else path)
    if dest.exists():
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with urllib.request.urlopen(url or MITMA + quote(path), timeout=120) as response:
            with NamedTemporaryFile(dir=dest.parent, delete=False) as staged:
                temporary = Path(staged.name)
                if province_table:
                    html = response.read().decode(response.headers.get_content_charset() or "iso-8859-15")
                else:
                    content_length = response.length
                    shutil.copyfileobj(response, staged)
                    if content_length is not None and staged.tell() != content_length:
                        raise OSError(f"Incomplete download for {dest}")
        if province_table:
            with temporary.open("w", encoding="utf-8", newline="") as output:
                write_ine_provinces(html, output)
        temporary.replace(dest)
        print("ok", dest.relative_to(RAW))
    except urllib.error.HTTPError as error:
        if not allow_missing or error.code not in (404, 410):
            raise OSError(f"HTTP {error.code} downloading {dest.relative_to(RAW)}") from error
        print("MISSING", dest.relative_to(RAW), error.code)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def download_inputs(start, end, *, allow_missing_days):
    # Zoning, INE <-> MITMA relation and documentation
    get(ZONE_MAPPING)
    get("LEEME_Especificaciones_indicadores_OpenDataMovilidad.xlsx", allow_missing=True)
    for level in ZONE_NAMES:
        get(zone_names_path(level))
        for ext in SHAPE_EXTENSIONS:
            get(zone_geometry_path(level, ext))
            get(zone_geometry_path(level, ext, centroid=True))

    # 2023 public holidays (BOE)
    get(BOE_HOLIDAYS, "https://www.boe.es/diario_boe/xml.php?id=BOE-A-2022-16755")

    # INE tables retain all published years.
    for table, path in INE_ADRH.items():
        get(path, f"{INE}{table}.csv")
    get(INE_DIRCE, f"{INE}4721.csv")
    get(INE_PROVINCES, INE_PROVINCES_URL, province_table=True)

    # Daily trips and overnight stays at all three levels
    for day in days_inclusive(start, end):
        for level in ZONE_NAMES:
            for dataset in DAILY_DATASETS:
                get(daily_mitma_path(day, level, dataset), allow_missing=allow_missing_days)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("start", nargs="?", type=date.fromisoformat)
    parser.add_argument("end", nargs="?", type=date.fromisoformat, help="Inclusive end date")
    parser.add_argument("--allow-missing-days", action="store_true", help="Continue when a daily file returns HTTP 404 or 410")
    args = parser.parse_args()
    start = args.start or SAMPLE_START
    end = args.end or args.start or SAMPLE_END
    if end < start:
        parser.error("end must be on or after start")
    try:
        download_inputs(start, end, allow_missing_days=args.allow_missing_days)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Download failed: {error}\n")


if __name__ == "__main__":
    main()

"""Download the mobility window and the reference inputs into data/raw."""

import shutil
import sys
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


def get(path, url=None, *, province_table=False):
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
    except urllib.error.HTTPError as e:
        print("MISSING", dest.relative_to(RAW), e.code)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    start = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else SAMPLE_START
    end = date.fromisoformat(sys.argv[2]) if len(sys.argv) > 2 else SAMPLE_END

    # Zoning, INE <-> MITMA relation and documentation
    get(ZONE_MAPPING)
    get("LEEME_Especificaciones_indicadores_OpenDataMovilidad.xlsx")
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
                get(daily_mitma_path(day, level, dataset))


if __name__ == "__main__":
    main()

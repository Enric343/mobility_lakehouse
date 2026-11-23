"""Source paths, reference inventory, and the INE province table reader."""

import csv
from datetime import date, timedelta
from html.parser import HTMLParser
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data/raw"
SAMPLE_START = date(2023, 3, 6)
SAMPLE_END = date(2023, 3, 12)
ZONE_NAMES = {"distritos": "distritos", "municipios": "municipios", "GAU": "gaus"}
DAILY_DATASETS = {"viajes": "Viajes", "pernoctaciones": "Pernoctaciones"}
SHAPE_EXTENSIONS = ("shp", "shx", "dbf", "prj", "cpg")
ZONE_MAPPING = "zonificacion/relacion_ine_zonificacionMitma.csv"
BOE_HOLIDAYS = "boe/fiestas_laborales/2023_BOE-A-2022-16755.xml"
INE_PROVINCES = "ine/ccaa_provincias.csv"
INE_PROVINCES_URL = "https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm"
INE_ADRH = {
    30832: "ine/adrh/indicadores_demograficos_30832.csv",
    30824: "ine/adrh/renta_media_mediana_30824.csv",
    30825: "ine/adrh/renta_fuentes_ingreso_30825.csv",
    37677: "ine/adrh/renta_gini_p80p20_37677.csv",
}
INE_DIRCE = "ine/dirce/empresas_municipio_4721.csv"


def days_inclusive(start, end):
    for offset in range((end - start).days + 1):
        yield start + timedelta(days=offset)


def daily_mitma_path(day, level, dataset):
    label = DAILY_DATASETS[dataset]
    return f"estudios_basicos/por-{level}/{dataset}/ficheros-diarios/{day:%Y-%m}/{day:%Y%m%d}_{label}_{level}.csv.gz"


def zone_names_path(level):
    return f"zonificacion/zonificacion_{level}/nombres_{ZONE_NAMES[level]}.csv"


def zone_geometry_path(level, extension, *, centroid=False):
    suffix = "_centroides" if centroid else ""
    return f"zonificacion/zonificacion_{level}/zonificacion_{ZONE_NAMES[level]}{suffix}.{extension}"


class ProvinceTable(HTMLParser):
    """Read the four-column INE table, including Ceuta and Melilla."""

    def __init__(self):
        super().__init__()
        self.rows = []
        self.row = None
        self.cell = None

    def handle_starttag(self, tag, attrs):
        if tag == "tr":
            self.row = []
        elif tag in ("td", "th") and self.row is not None:
            self.cell = []

    def handle_data(self, data):
        if self.cell is not None:
            self.cell.append(data)

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self.cell is not None:
            self.row.append(" ".join("".join(self.cell).split()))
            self.cell = None
        elif tag == "tr" and self.row is not None:
            if len(self.row) == 4 and self.row[0].isdigit() and self.row[2].isdigit():
                self.rows.append(self.row)
            self.row = None


def write_ine_provinces(html, output):
    parser = ProvinceTable()
    parser.feed(html)
    parser.close()
    rows = parser.rows
    if len(rows) != 52 or len({row[2] for row in rows}) != 52 or len({row[0] for row in rows}) != 19:
        raise ValueError("The INE page did not contain 52 provinces across 19 autonomous communities and cities")
    writer = csv.writer(output, delimiter=";", lineterminator="\n")
    writer.writerow(("CODAUTO", "Comunidad Autónoma", "CPRO", "Provincia"))
    writer.writerows(rows)

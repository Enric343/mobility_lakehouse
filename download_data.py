import sys
import urllib.error
import urllib.request
from datetime import date, timedelta
from pathlib import Path
from urllib.parse import quote

MITMA = "https://movilidad-opendata.mitma.es/"
INE = "https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/"
RAW = Path(__file__).parent / "data" / "raw"


# Downloads a file of the MITMA bucket into data/raw/mitma/ (or from url), skipping it if it already exists
def get(path, url=None):
    dest = RAW / ("mitma/" + path if url is None else path)
    if dest.exists():
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        urllib.request.urlretrieve(url or MITMA + quote(path), dest)
        print("ok", dest.relative_to(RAW))
    except urllib.error.HTTPError as e:
        print("MISSING", dest.relative_to(RAW), e.code)


start = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date(2023, 3, 6)
end = date.fromisoformat(sys.argv[2]) if len(sys.argv) > 2 else date(2023, 3, 12)

# Zoning, INE <-> MITMA relation and documentation
get("zonificacion/relacion_ine_zonificacionMitma.csv")
get("LEEME_Especificaciones_indicadores_OpenDataMovilidad.xlsx")
for folder, name in [("distritos", "distritos"), ("municipios", "municipios"), ("GAU", "gaus")]:
    get(f"zonificacion/zonificacion_{folder}/nombres_{name}.csv")
    for ext in ["shp", "shx", "dbf", "prj", "cpg"]:
        get(f"zonificacion/zonificacion_{folder}/zonificacion_{name}.{ext}")
        get(f"zonificacion/zonificacion_{folder}/zonificacion_{name}_centroides.{ext}")

# 2023 public holidays (BOE)
get("boe/fiestas_laborales/2023_BOE-A-2022-16755.xml", "https://www.boe.es/diario_boe/xml.php?id=BOE-A-2022-16755")

# INE tables, with all their years (the list of provinces and regions is copied by hand from the INE website)
for path, table in [("adrh/indicadores_demograficos", 30832), ("adrh/renta_media_mediana", 30824),
                    ("adrh/renta_fuentes_ingreso", 30825), ("adrh/renta_gini_p80p20", 37677), ("dirce/empresas_municipio", 4721)]:
    get(f"ine/{path}_{table}.csv", f"{INE}{table}.csv")

# Daily trips and overnight stays of the 3 levels
day = start
while day <= end:
    ym, ymd = day.strftime("%Y-%m"), day.strftime("%Y%m%d")
    for level in ["distritos", "municipios", "GAU"]:
        get(f"estudios_basicos/por-{level}/viajes/ficheros-diarios/{ym}/{ymd}_Viajes_{level}.csv.gz")
        get(f"estudios_basicos/por-{level}/pernoctaciones/ficheros-diarios/{ym}/{ymd}_Pernoctaciones_{level}.csv.gz")
    day += timedelta(days=1)

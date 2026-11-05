# Data Sources

The data we use and what we use it for. Files are in `data/raw/` (not in git). `{level}` = `distritos`, `municipios` or `GAU`.

Business questions: **BQ1** typical day, **BQ2** gravity model and infrastructure gaps, **BQ3** overnight stays.

## MITMA

Source: <https://movilidad-opendata.mitma.es/>

| Data | File (in `mitma/`) | What for |
|---|---|---|
| Trips | `estudios_basicos/por-{level}/viajes/ficheros-diarios/YYYY-MM/YYYYMMDD_Viajes_{level}.csv.gz` | BQ1 and BQ2: trips per hour and between zones |
| Overnight stays | `estudios_basicos/por-{level}/pernoctaciones/ficheros-diarios/YYYY-MM/YYYYMMDD_Pernoctaciones_{level}.csv.gz` | BQ3: where people sleep and where they live |
| INE to MITMA relation | `zonificacion/relacion_ine_zonificacionMitma.csv` | Move INE data to MITMA zones, and know the province of each zone |
| Zone names | `zonificacion/zonificacion_{level}/nombres_*.csv` | Name of each zone |
| Zone polygons | `zonificacion/zonificacion_{level}/zonificacion_*.shp` (and `.shx .dbf .prj .cpg`) | Maps for the article |
| Zone centroids | `zonificacion/zonificacion_{level}/zonificacion_*_centroides.shp` (and `.shx .dbf .prj .cpg`) | BQ2: distance between zones (`d_ij`) |
| Column dictionary | `LEEME_Especificaciones_indicadores_OpenDataMovilidad.xlsx` | Meaning of each column |

## INE

| Data | File (in `ine/`) | What for |
|---|---|---|
| Population and demographics ([30832](https://www.ine.es/jaxiT3/Tabla.htm?t=30832)) | `adrh/indicadores_demograficos_30832.csv` | BQ2: population of the origin (`P_i`). Also mean age and % aged 65+ |
| Income ([30824](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)) | `adrh/renta_media_mediana_30824.csv` | BQ2: rank the worst-served zones by income |
| Income sources ([30825](https://www.ine.es/jaxiT3/Tabla.htm?t=30825)) | `adrh/renta_fuentes_ingreso_30825.csv` | Describe each zone: % of income from wages, pensions and unemployment benefits |
| Inequality ([37677](https://www.ine.es/jaxiT3/Tabla.htm?t=37677)) | `adrh/renta_gini_p80p20_37677.csv` | Describe each zone: Gini index |
| Businesses ([4721](https://www.ine.es/jaxiT3/Tabla.htm?t=4721)) | `dirce/empresas_municipio_4721.csv` | BQ2: economic activity of the destination (`E_j`) |
| Provinces and regions ([list](https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm)) | `ccaa_provincias.csv` | BQ1: know the region of each province, to apply regional holidays |

## BOE

| Data | File (in `boe/`) | What for |
|---|---|---|
| 2023 public holidays ([BOE-A-2022-16755](https://www.boe.es/diario_boe/txt.php?id=BOE-A-2022-16755)) | `fiestas_laborales/2023_BOE-A-2022-16755.xml` | BQ1: know which days are holidays in each region |

## How to get the data

**MITMA, BOE and INE tables:** `python download_data.py [start] [end]`. Without dates it downloads the sample week, 2023-03-06 to 2023-03-12. The rest of 2023 is about 130 GB (estimated from the sample week): `python download_data.py 2023-01-01 2023-12-31`.

MITMA has no files for 7 days of 2023: 26, 27, 30 and 31 October and 1, 2 and 3 November. The script reports them as `MISSING` and carries on.

The INE tables come with all their years. Silver filters to 2023, and the other years help explain the nulls.

**Provinces and regions, by hand:** the list is only a web page, so copy its table to `data/raw/ine/ccaa_provincias.csv`, separated by `;`, with the columns `CODAUTO;Comunidad Autónoma;CPRO;Provincia`.

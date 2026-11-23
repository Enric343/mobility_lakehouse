# `bronze_mitma_od_daily`

Published daily trip flows as delivered by MITMA.

| Property | Detail |
|---|---|
| Grain and key | One published observation per date, zoning level, hour, origin, destination, activity pair and traveller profile. |
| Inputs | MITMA daily `Viajes` CSV.gz for each level. |
| Transformation | • Read every source column as text (no casting).<br>• Add `zone_level` (from the folder) and the `_source_file` / `_ingested_at` lineage.<br>• Keep source privacy markers (`NA`) visible.<br>[CSV staging](../../sql/ingestion/mobility_day.sql) |
| Storage | Parquet partitioned by (`zone_level`, `fecha`). |
| Validation | Checks dates, source-grain duplicates, zone IDs and nonnegative finite volumes. [Daily trip checks](../../sql/validation/bronze_trips.sql) |
| Used by | [`silver_fact_trips`](silver_fact_trips.md) |

## Columns

All source columns are kept as published text (`VARCHAR`).

| Column | Description |
|---|---|
| `fecha` | Day `YYYYMMDD` |
| `periodo` | Hour `00`–`23` |
| `origen`, `destino` | Zone code at the level; also foreign NUTS-3 (`FR*`, `PT*`) and `externo` |
| `distancia` | Distance band in km: `0.5-2`, `2-10`, `10-50`, `>50` |
| `actividad_origen`, `actividad_destino` | `casa`, `trabajo_estudio`, `frecuente`, `no_frecuente` |
| `estudio_origen_posible`, `estudio_destino_posible` | `si` / `no` |
| `residencia` | Province of residence (2 digits) |
| `renta` | Income band (thousand €): `<10`, `10-15`, `>15` |
| `edad` | `0-25`, `25-45`, `45-65`, `65-100`, `NA` |
| `sexo` | `hombre`, `mujer`, `NA` |
| `viajes` | Number of trips (expanded, decimal) |
| `viajes_km` | Total km of the row (trips × km) |
| `zone_level` | Added: `distritos`, `municipios`, `GAU` |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT fecha, periodo, origen, destino, viajes, _source_file
FROM lake.main.bronze_mitma_od_daily
WHERE zone_level = 'municipios' AND fecha = '20230306'
LIMIT 10;
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

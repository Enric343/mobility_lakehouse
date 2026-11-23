# `bronze_mitma_overnight_daily`

Published overnight counts by residence and sleeping location.

| Property | Detail |
|---|---|
| Grain and key | One observation per (`fecha`, `zone_level`, `zona_residencia`, `zona_pernoctacion`). Residence is a district. |
| Inputs | MITMA daily `Pernoctaciones` CSV.gz for each destination zoning level. |
| Transformation | • Keep the source codes and person counts as text.<br>• Add `zone_level` and the `_source_file` / `_ingested_at` lineage.<br>[CSV staging](../../sql/ingestion/mobility_day.sql) |
| Storage | Parquet partitioned by (`zone_level`, `fecha`). |
| Validation | Checks dates, source keys, both zone references and published person counts. [Daily overnight checks](../../sql/validation/bronze_overnight.sql) |
| Used by | [`silver_fact_overnight`](silver_fact_overnight.md) |

## Columns

All source columns are kept as published text (`VARCHAR`).

| Column | Description |
|---|---|
| `fecha` | Day `YYYYMMDD` |
| `zona_residencia` | Residence district (a district in all three files) |
| `zona_pernoctacion` | Overnight zone, at the file's level |
| `personas` | Number of people (decimal) |
| `zone_level` | Added: `distritos`, `municipios`, `GAU` |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT zona_residencia, zona_pernoctacion, personas, _source_file
FROM lake.main.bronze_mitma_overnight_daily
WHERE zone_level = 'GAU' AND fecha = '20230306'
LIMIT 10;
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

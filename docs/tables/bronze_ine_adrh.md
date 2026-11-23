# `bronze_ine_adrh`

Published INE Atlas of Household Income indicators in source format.

| Property | Detail |
|---|---|
| Grain and key | One published value per source table, territorial unit, year and indicator. |
| Inputs | INE ADRH tables `30832`, `30824`, `30825` and `37677`. |
| Transformation | • Stack the four source tables, renaming the indicator header to `indicador`.<br>• Add `table_id` from the file name.<br>• Keep all years, territorial levels and the Spanish number text.<br>[INE ingestion](../../sql/ingestion/ine.sql) |
| Storage | Parquet partitioned by `table_id`. |
| Validation | Checks that each source table includes 2023 rows. Silver validates the selected indicators. [Bronze reference checks](../../sql/validation/reference_bronze.sql) |
| Used by | [`silver_zone_metrics`](silver_zone_metrics.md) |

## Columns

The four source tables share this layout; only the indicator column header differs, so it is renamed to `indicador`. All columns are `VARCHAR`.

| Column | Description |
|---|---|
| `Municipios` | Code + name in one field |
| `Distritos` | Empty on municipality rows |
| `Secciones` | Empty on municipality and district rows |
| `indicador` | Indicator name (renamed from each table's header) |
| `Periodo` | Year |
| `Total` | Spanish number text; empty, `.` or `..` means no value |
| `table_id` | Added, from the file name: `30832`, `30824`, `30825`, `37677` |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT table_id, Secciones, indicador, Total
FROM lake.main.bronze_ine_adrh
WHERE table_id = '30832' AND Periodo = '2023'
  AND Secciones IS NOT NULL AND indicador = 'Población'
LIMIT 10;
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

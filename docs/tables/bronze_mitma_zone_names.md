# `bronze_mitma_zone_names`

Names attached to MITMA zone identifiers.

| Property | Detail |
|---|---|
| Grain and key | One name per (`zone_level`, `ID`). |
| Inputs | MITMA `nombres_*.csv` for districts, municipalities and GAU. |
| Transformation | • Keep `ID` and `name`; drop the source index column.<br>• Add `zone_level` and the lineage columns.<br>[Reference ingestion](../../sql/ingestion/mitma_reference.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks unique IDs, non-empty names and corresponding polygons and centroids. [Bronze reference checks](../../sql/validation/reference_bronze.sql) |
| Used by | [`silver_dim_zone`](silver_dim_zone.md) |

## Columns

3,792 districts, 2,618 municipalities and 2,086 GAU. All columns are `VARCHAR`.

| Column | Description |
|---|---|
| `ID` | Zone code (`01004_AM`, `GAU A Coruña`) |
| `name` | Zone name |
| `zone_level` | Added: `distritos`, `municipios`, `GAU` |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT ID, name
FROM lake.main.bronze_mitma_zone_names
WHERE zone_level = 'municipios'
LIMIT 10;
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

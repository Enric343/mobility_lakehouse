# `bronze_mitma_zone_mapping`

Correspondence between INE census geography and MITMA zones.

| Property | Detail |
|---|---|
| Grain and key | One correspondence per mapped INE section. Rows with `seccion_ine = 'NA'` preserve source placeholders. |
| Inputs | MITMA `relacion_ine_zonificacionMitma.csv`. |
| Transformation | • Keep the six original INE/MITMA codes as text.<br>• Add the `_source_file` / `_ingested_at` lineage.<br>[Reference ingestion](../../sql/ingestion/mitma_reference.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks unique populated sections, province consistency, zone coverage and MITMA parent relationships. [Bronze reference checks](../../sql/validation/reference_bronze.sql) |
| Used by | [`silver_dim_zone`](silver_dim_zone.md) and [`silver_zone_metrics`](silver_zone_metrics.md) |

## Columns

One row per INE census section (36,382 rows; 49 with `NA` for unpopulated lands). All columns are `VARCHAR`.

| Column | Description |
|---|---|
| `seccion_ine` | INE census section code |
| `distrito_ine` | INE district code |
| `municipio_ine` | INE municipality code |
| `distrito_mitma` | MITMA district zone |
| `municipio_mitma` | MITMA municipality zone |
| `gau_mitma` | MITMA GAU zone |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT seccion_ine, distrito_mitma, municipio_mitma, gau_mitma
FROM lake.main.bronze_mitma_zone_mapping
WHERE municipio_ine = '28079'
LIMIT 10;
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

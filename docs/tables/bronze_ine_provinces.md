# `bronze_ine_provinces`

The official province list with community codes.

| Property | Detail |
|---|---|
| Grain and key | One row per province code `CPRO`. |
| Inputs | INE province and community HTML table, downloaded as a semicolon-separated CSV. |
| Transformation | Preserves province and community codes as text, including leading zeros. [INE ingestion](../../sql/ingestion/ine.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks coverage of 52 provinces and 19 autonomous communities and cities. [Bronze reference checks](../../sql/validation/reference_bronze.sql) |
| Used by | [`silver_dim_ccaa`](silver_dim_ccaa.md) and [`silver_dim_province`](silver_dim_province.md) |

## Columns

52 rows. All columns are `VARCHAR`; codes keep their leading zeros.

| Column | Description |
|---|---|
| `CODAUTO` | Autonomous community code |
| `Comunidad Autónoma` | Community name |
| `CPRO` | Province code |
| `Provincia` | Province name |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT CPRO, Provincia, CODAUTO, "Comunidad Autónoma"
FROM lake.main.bronze_ine_provinces
ORDER BY CPRO
LIMIT 10;
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

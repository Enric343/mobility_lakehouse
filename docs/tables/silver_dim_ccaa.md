# `silver_dim_ccaa`

Autonomous communities and cities used in administrative and calendar joins.

| Property | Detail |
|---|---|
| Grain and key | One row per `ccaa_code`. |
| Inputs | [`bronze_ine_provinces`](bronze_ine_provinces.md) |
| Transformation | Deduplicates the INE community code and label across its provinces. [Dimension SQL](../../sql/bronze_to_silver/dimensions.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks unique community keys and province and holiday references. [Silver reference checks](../../sql/validation/reference_silver.sql) |
| Used by | [`silver_dim_province`](silver_dim_province.md) and [`silver_holidays`](silver_holidays.md) |

## Columns

19 autonomous communities and cities.

| Column | Type | Description |
|---|---|---|
| `ccaa_code` | VARCHAR | Community code, from INE `CODAUTO`. PK |
| `ccaa` | VARCHAR | Community name, from INE `Comunidad Autónoma` |

## Inspect the data

```sql
SELECT ccaa_code, ccaa
FROM lake.main.silver_dim_ccaa
ORDER BY ccaa_code
LIMIT 10;
```

[Table catalog](README.md) · [Silver column contract](../../sql/schema/silver.sql)

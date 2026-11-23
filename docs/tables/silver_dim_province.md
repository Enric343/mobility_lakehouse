# `silver_dim_province`

Province keys, names and parent communities.

| Property | Detail |
|---|---|
| Grain and key | One row per `province_code`. |
| Inputs | [`bronze_ine_provinces`](bronze_ine_provinces.md) |
| Transformation | Maps INE `CPRO` and `CODAUTO` to Silver province and community keys. [Dimension SQL](../../sql/bronze_to_silver/dimensions.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks unique province codes and that all communities exist. [Silver reference checks](../../sql/validation/reference_silver.sql) |
| Used by | [`silver_dim_zone`](silver_dim_zone.md) and BQ1 calendar joins. |

## Columns

52 provinces. Links each zone to its community, and so to regional holidays.

| Column | Type | Description |
|---|---|---|
| `province_code` | VARCHAR | Province code, from INE `CPRO`. PK |
| `province_name` | VARCHAR | Province name, from INE `Provincia` |
| `ccaa_code` | VARCHAR | Community it belongs to, from INE `CODAUTO`. FK → `silver_dim_ccaa` |

## Inspect the data

```sql
SELECT province_code, province_name, ccaa_code
FROM lake.main.silver_dim_province
ORDER BY province_code
LIMIT 10;
```

[Table catalog](README.md) · [Silver column contract](../../sql/schema/silver.sql)

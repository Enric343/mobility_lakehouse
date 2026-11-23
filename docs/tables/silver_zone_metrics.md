# `silver_zone_metrics`

2023 population, income and business metrics by MITMA zone.

| Property | Detail |
|---|---|
| Grain and key | One row per (`zone_level`, `zone_id`) with population metrics. The snapshot is fixed to 2023. |
| Inputs | [`bronze_ine_adrh`](bronze_ine_adrh.md), [`bronze_ine_dirce`](bronze_ine_dirce.md), [`bronze_mitma_zone_mapping`](bronze_mitma_zone_mapping.md) |
| Transformation | • Map each populated INE census section to a MITMA zone.<br>• Sum population per zone; compute income, Gini and demographics as population-weighted means.<br>• Add DIRCE business counts at `municipios`/`GAU` (null for `distritos`).<br>[Metrics SQL](../../sql/bronze_to_silver/zone_metrics.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks zone references, section assignments, published indicators and population and business totals. [Silver reference checks](../../sql/validation/reference_silver.sql) |
| Used by | [`gold_infrastructure_gaps`](gold_infrastructure_gaps.md) for population and business inputs. |

## Columns

Fixed to 2023. INE values are taken per census section and aggregated to each MITMA level via `bronze_mitma_zone_mapping`. Weighted means ignore sections with no value in both numerator and denominator.

| Column | Type | Description |
|---|---|---|
| `zone_level`, `zone_id` | VARCHAR | PK, FK → `silver_dim_zone` |
| `population` | DOUBLE | Sum of section population (table 30832) → `P_i` |
| `mean_income_per_person` | DOUBLE | Table 30824, mean weighted by section population |
| `pct_income_wages`, `pct_income_pensions`, `pct_income_unemployment` | DOUBLE | Table 30825, weighted mean |
| `gini` | DOUBLE | Table 37677, weighted mean (approximation) |
| `mean_age`, `pct_over_65` | DOUBLE | Table 30832, weighted mean |
| `businesses_total` | INTEGER | DIRCE `Total` → `E_j`. `NULL` at district level |
| `businesses_industry`, `businesses_construction`, `businesses_trade_transport_hospitality`, `businesses_services` | INTEGER | DIRCE groups. Empty = `NULL`, not 0. `NULL` at district level |

DIRCE is published per municipality, so business columns are filled for `municipios` and `GAU` and are `NULL` for `distritos`.

## Inspect the data

```sql
SELECT zone_id, population, mean_income_per_person, businesses_total
FROM lake.main.silver_zone_metrics
WHERE zone_level = 'municipios'
LIMIT 10;
```

[Table catalog](README.md) · [Silver column contract](../../sql/schema/silver.sql) · [Mapping and aggregation rules](../bronze-to-silver.md#population-income-and-businesses-by-zone)

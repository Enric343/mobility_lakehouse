# `gold_hourly_demand`

Average hourly network demand by calendar type or fit cluster.

| Property | Detail |
|---|---|
| Grain and key | The inclusive window (`period_start`, `period_end`), followed by (`zone_level`, `pattern_basis`, `pattern`, `hour_of_day`). |
| Inputs | Hourly network profiles from [`silver_fact_trips`](silver_fact_trips.md) and daily labels from the same run. |
| Transformation | • Sum published OD trips into one network total per hour.<br>• Average those hourly totals across the days in each pattern.<br>[Hourly demand SQL](../../sql/silver_to_gold/hourly_demand.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Weighted hourly means reconstruct published volume separately for both pattern bases. [Gold validation](../../sql/validation/gold.sql) |
| Used by | The BQ1 hourly curves. |

## Columns

| Column | Type | Description |
|---|---|---|
| `period_start`, `period_end` | DATE | Inclusive reporting window |
| `zone_level` | VARCHAR | `distritos`, `municipios`, `GAU` |
| `pattern_basis` | VARCHAR | `calendar` or `cluster` |
| `pattern` | VARCHAR | Day type or cluster within the basis |
| `hour_of_day` | BIGINT | 0–23 |
| `avg_hourly_trips` | DOUBLE | Network-wide hourly mean |
| `observed_days` | BIGINT | Days contributing to the mean |

## Inspect the data

```sql
SELECT hour_of_day, avg_hourly_trips, observed_days
FROM lake.main.gold_hourly_demand
WHERE period_start = DATE '2023-03-06' AND period_end = DATE '2023-03-12'
  AND zone_level = 'municipios' AND pattern_basis = 'calendar'
  AND pattern = 'weekday'
ORDER BY hour_of_day;
```

[Table catalog](README.md) · [Gold DDL](../../sql/schema/gold.sql)

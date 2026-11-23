# `gold_typical_day_patterns`

Typical hourly OD matrices by calendar day type or fitted cluster.

| Property | Detail |
|---|---|
| Grain and key | The inclusive window (`period_start`, `period_end`), followed by (`zone_level`, `pattern_basis`, `day_type`, `hour_of_day`, `origin_zone_id`, `destination_zone_id`). |
| Inputs | [`silver_fact_trips`](silver_fact_trips.md), [`silver_holidays`](silver_holidays.md) and [`gold_day_assignments`](gold_day_assignments.md) labels from the same run. |
| Transformation | • Sum activities into each daily OD-hour total.<br>• Average those totals over the published days of each pattern.<br>• `observed_days` is the denominator; use one `pattern_basis` per comparison.<br>[Typical-day SQL](../../sql/silver_to_gold/typical_day.sql) |
| Storage | Parquet partitioned by window, `zone_level` and `pattern_basis`. |
| Validation | Weighted reconstruction using `avg_hourly_trips × observed_days` matches published trips per level and basis. [Gold validation](../../sql/validation/gold.sql) |
| Used by | BQ1 OD comparisons and downstream queries. |

## Columns

| Column | Type | Description |
|---|---|---|
| `period_start`, `period_end` | DATE | Inclusive reporting window |
| `zone_level` | VARCHAR | `distritos`, `municipios`, `GAU` |
| `pattern_basis` | VARCHAR | `calendar` or `cluster`; pick one per comparison |
| `day_type` | VARCHAR | `weekday` / `weekend` / `holiday`, or `cluster_1` / `cluster_2` |
| `hour_of_day` | BIGINT | 0–23 |
| `origin_zone_id`, `destination_zone_id` | VARCHAR | Silver zone keys |
| `avg_hourly_trips` | DOUBLE | Mean of published daily OD-hour totals for the pattern |
| `observed_days` | BIGINT | Days with a published observation (the denominator) |

## Inspect the data

```sql
SELECT day_type, hour_of_day, destination_zone_id, avg_hourly_trips, observed_days
FROM lake.main.gold_typical_day_patterns
WHERE period_start = DATE '2023-03-06' AND period_end = DATE '2023-03-12'
  AND zone_level = 'municipios' AND pattern_basis = 'calendar'
  AND origin_zone_id = '28079'
LIMIT 10;
```

[Table catalog](README.md) · [Gold DDL](../../sql/schema/gold.sql)

# `gold_origin_demand`

Average daily trips departing each zone by calendar day type.

| Property | Detail |
|---|---|
| Grain and key | The inclusive window (`period_start`, `period_end`), followed by (`zone_level`, `origin_zone_id`, `day_type`). |
| Inputs | Daily OD totals from [`silver_fact_trips`](silver_fact_trips.md) with origin calendar labels. |
| Transformation | • Sum all published destinations and hours into one daily total per origin.<br>• Average those daily totals over the observed days of each `day_type`.<br>[Origin demand SQL](../../sql/silver_to_gold/origin_demand.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Weighted origin averages reconstruct published totals at each zoning level. [Gold validation](../../sql/validation/gold.sql) |
| Used by | The weekday-to-weekend map in the BQ1 report. |

## Columns

| Column | Type | Description |
|---|---|---|
| `period_start`, `period_end` | DATE | Inclusive reporting window |
| `zone_level` | VARCHAR | `distritos`, `municipios`, `GAU` |
| `origin_zone_id` | VARCHAR | Origin zone |
| `day_type` | VARCHAR | Calendar label |
| `avg_daily_trips` | DOUBLE | Mean daily trips departing the origin |
| `observed_days` | BIGINT | Days observed for that origin and type |

## Inspect the data

```sql
SELECT origin_zone_id, day_type, avg_daily_trips, observed_days
FROM lake.main.gold_origin_demand
WHERE period_start = DATE '2023-03-06' AND period_end = DATE '2023-03-12'
  AND zone_level = 'municipios' AND origin_zone_id = '28079'
ORDER BY day_type;
```

[Table catalog](README.md) · [Gold DDL](../../sql/schema/gold.sql)

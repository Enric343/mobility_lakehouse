# `gold_day_assignments`

Daily network summaries and their calendar and cluster labels.

| Property | Detail |
|---|---|
| Grain and key | The inclusive window (`period_start`, `period_end`), followed by (`zone_level`, `date`). |
| Inputs | [`silver_fact_trips`](silver_fact_trips.md) |
| Transformation | • Fit two k-means clusters per level on each day's hourly profile shape.<br>• Label each day with its cluster, calendar type, total trips and peak hour.<br>[Clustering](../../scripts/lakehouse/clustering.py) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Each expected day receives one label and each level has two clusters. [Gold validation](../../sql/validation/gold.sql) |
| Used by | [`gold_hourly_demand`](gold_hourly_demand.md) and the BQ1 report. |

## Columns

| Column | Type | Description |
|---|---|---|
| `period_start`, `period_end` | DATE | Inclusive reporting window |
| `zone_level` | VARCHAR | `distritos`, `municipios`, `GAU` |
| `date` | DATE | Calendar day |
| `day_type` | VARCHAR | Calendar label: `weekday` / `weekend` / `holiday` |
| `cluster_id` | INTEGER | K-means cluster for the day's hourly shape (two per level) |
| `total_trips` | DOUBLE | Published daily trips |
| `peak_hour` | BIGINT | Hour with the most trips |

## Inspect the data

```sql
SELECT date, day_type, cluster_id, total_trips, peak_hour
FROM lake.main.gold_day_assignments
WHERE period_start = DATE '2023-03-06' AND period_end = DATE '2023-03-12' AND zone_level = 'municipios'
ORDER BY date;
```

[Table catalog](README.md) · [Gold DDL](../../sql/schema/gold.sql)

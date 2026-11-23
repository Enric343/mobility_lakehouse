# `gold_infrastructure_gaps`

Observed and estimated weekly trips for eligible directed municipality pairs.

| Property | Detail |
|---|---|
| Grain and key | The inclusive window (`period_start`, `period_end`), followed by (`zone_level`, `origin_zone_id`, `destination_zone_id`). The analysis uses municipalities. |
| Inputs | [`silver_fact_trips`](silver_fact_trips.md), [`silver_zone_metrics`](silver_zone_metrics.md), [`silver_dim_zone`](silver_dim_zone.md) |
| Transformation | • Build eligible pairs with positive origin population, destination businesses and centroid distance.<br>• Estimate trips with the gravity formula; sum published trips as `actual_trips`.<br>• Leave `actual_trips` and the ratio null where no flow is published.<br>[Pair results SQL](../../sql/silver_to_gold/infrastructure_gaps.sql) |
| Storage | Parquet partitioned by (`period_start`, `period_end`). |
| Validation | Validates eligible pairs, positive estimates, unpublished-flow handling and calibrated comparable trip totals. [Gold validation](../../sql/validation/gold.sql) |
| Used by | [`gold_gravity_zone_ranking`](gold_gravity_zone_ranking.md) |

## Columns

Directed municipality pairs. Eligible pairs with no published flow keep `actual_trips` and the ratio null.

| Column | Type | Description |
|---|---|---|
| `period_start`, `period_end` | DATE | Inclusive window for trips and calibration |
| `zone_level` | VARCHAR | `municipios` |
| `origin_zone_id`, `destination_zone_id` | VARCHAR | Directed domestic pair |
| `origin_population` | DOUBLE | `silver_zone_metrics.population` at the origin |
| `destination_businesses` | INTEGER | `silver_zone_metrics.businesses_total` at the destination |
| `distance_km` | DOUBLE | Great-circle distance between centroids |
| `actual_trips` | DOUBLE | Sum of published trips over the window |
| `estimated_trips` | DOUBLE | `k × population × businesses / distance_km²` |
| `actual_to_estimated_ratio` | DOUBLE | Actual / estimated when both exist and the estimate is positive |

## Inspect the data

```sql
SELECT destination_zone_id, distance_km, actual_trips, estimated_trips
FROM lake.main.gold_infrastructure_gaps
WHERE period_start = DATE '2023-03-06' AND period_end = DATE '2023-03-12' AND origin_zone_id = '28079'
LIMIT 10;
```

[Table catalog](README.md) · [Gold DDL](../../sql/schema/gold.sql)

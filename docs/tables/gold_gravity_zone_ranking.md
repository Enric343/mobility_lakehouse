# `gold_gravity_zone_ranking`

Gravity comparison and publication coverage by municipality origin.

| Property | Detail |
|---|---|
| Grain and key | The inclusive window (`period_start`, `period_end`), followed by (`zone_level`, `origin_zone_id`). |
| Inputs | [`gold_infrastructure_gaps`](gold_infrastructure_gaps.md) |
| Transformation | • Per origin, divide observed trips by estimated trips over the same published pairs → `service_ratio`.<br>• Compute `pair_coverage` as observed ÷ eligible destinations.<br>• Rank origins by ascending `service_ratio` → `gap_rank`.<br>[Ranking SQL](../../sql/silver_to_gold/gravity_zone_ranking.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks unique origins and assigned ranks and reconciles pair counts and comparable volumes. [Gold validation](../../sql/validation/gold.sql) |
| Used by | The BQ2 map, coverage plot and rankings. |

## Columns

One row per municipality origin. A low `service_ratio` is a gap relative to the model for the window.

| Column | Type | Description |
|---|---|---|
| `period_start`, `period_end` | DATE | Inclusive reporting window |
| `zone_level` | VARCHAR | `municipios` |
| `origin_zone_id` | VARCHAR | Origin municipality |
| `origin_population` | DOUBLE | Origin population |
| `eligible_pairs` | BIGINT | Eligible destinations |
| `observed_pairs` | BIGINT | Eligible destinations with a published flow |
| `pair_coverage` | DOUBLE | `observed_pairs / eligible_pairs` |
| `actual_trips` | DOUBLE | Observed trips over observed pairs |
| `estimated_on_observed_pairs` | DOUBLE | Gravity estimate over the same pairs |
| `service_ratio` | DOUBLE | `actual_trips / estimated_on_observed_pairs` |
| `gap_rank` | BIGINT | Ascending rank by `service_ratio` |

## Inspect the data

```sql
SELECT gap_rank, origin_zone_id, service_ratio, pair_coverage
FROM lake.main.gold_gravity_zone_ranking
WHERE period_start = DATE '2023-03-06' AND period_end = DATE '2023-03-12' AND gap_rank IS NOT NULL
ORDER BY gap_rank
LIMIT 10;
```

[Table catalog](README.md) · [Gold DDL](../../sql/schema/gold.sql)

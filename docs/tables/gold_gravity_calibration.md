# `gold_gravity_calibration`

Fitted multiplier and evidence for the municipality gravity model.

| Property | Detail |
|---|---|
| Grain and key | The inclusive window (`period_start`, `period_end`), followed by `zone_level` (`municipios`). |
| Inputs | Eligible directed pairs from Silver trips, zone statistics and centroids. |
| Transformation | Fits `k` as observed volume divided by total gravity weight on eligible published pairs. [Calibration SQL](../../sql/silver_to_gold/gravity_calibration.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks a positive finite coefficient and agreement between the observed fit volume and published-pair estimates. [Gold validation](../../sql/validation/gold.sql) |
| Used by | [`gold_infrastructure_gaps`](gold_infrastructure_gaps.md) estimates and the BQ2 report. |

## Columns

One row per window. `k` is fitted over eligible pairs that have a published flow.

| Column | Type | Description |
|---|---|---|
| `period_start`, `period_end` | DATE | Inclusive reporting window |
| `zone_level` | VARCHAR | `municipios` |
| `gravity_k` | DOUBLE | Fitted multiplier `k` |
| `eligible_pairs` | BIGINT | Candidate directed pairs |
| `observed_pairs` | BIGINT | Eligible pairs with a published flow |
| `observed_trips` | DOUBLE | Published trips used in the fit |
| `estimated_on_observed_pairs` | DOUBLE | Gravity estimate over those pairs |

## Inspect the data

```sql
SELECT gravity_k, eligible_pairs, observed_pairs, observed_trips
FROM lake.main.gold_gravity_calibration
WHERE period_start = DATE '2023-03-06' AND period_end = DATE '2023-03-12';
```

[Table catalog](README.md) · [Gold DDL](../../sql/schema/gold.sql)

# `silver_fact_trips`

Typed and aggregated trip flows by OD-hour and activity.

| Property | Detail |
|---|---|
| Grain and key | One row per (`trip_datetime`, `zone_level`, `origin_zone_id`, `destination_zone_id`, `origin_activity`, `destination_activity`). |
| Inputs | [`bronze_mitma_od_daily`](bronze_mitma_od_daily.md) |
| Transformation | • Build `trip_datetime` from `fecha` + `periodo` (date + hour → `TIMESTAMP`).<br>• Drop the traveller-profile columns (distance, study, residence, income, age, sex).<br>• Sum `viajes` over each remaining origin × destination × activity pair.<br>[Trip transformation](../../sql/bronze_to_silver/fact_trips.sql) |
| Storage | Parquet partitioned by level and timestamp year, month and day. |
| Validation | Checks zone references at the file level and conserves volume from Bronze. [Daily batch loader](../../scripts/lakehouse/mobility.py) |
| Used by | [`gold_typical_day_patterns`](gold_typical_day_patterns.md) and [`gold_infrastructure_gaps`](gold_infrastructure_gaps.md) |

## Columns

Primary key is every column except `trips`; the source profile columns (distance, study, residence, income, age, sex) are dropped and their trips summed.

| Column | Type | Description |
|---|---|---|
| `trip_datetime` | TIMESTAMP | Observation hour, built from Bronze `fecha` + `periodo` |
| `zone_level` | VARCHAR | Zoning level: `distritos`, `municipios` or `GAU` |
| `origin_zone_id`, `destination_zone_id` | VARCHAR | Origin and destination zones, from Bronze `origen`, `destino`. FK → `silver_dim_zone` |
| `origin_activity`, `destination_activity` | VARCHAR | Activity at each end, from Bronze `actividad_origen`, `actividad_destino` |
| `trips` | DOUBLE | Number of trips, summed from Bronze `viajes` |

## Inspect the data

```sql
SELECT trip_datetime, origin_zone_id, destination_zone_id, trips
FROM lake.main.silver_fact_trips
WHERE zone_level = 'municipios'
  AND trip_datetime >= TIMESTAMP '2023-03-06 00:00:00'
  AND trip_datetime <  TIMESTAMP '2023-03-07 00:00:00'
LIMIT 10;
```

[Table catalog](README.md) · [Silver column contract](../../sql/schema/silver.sql) · [DuckLake layout](../../sql/schema/ducklake.sql)

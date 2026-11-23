# `silver_fact_overnight`

Typed person counts by residence district and sleeping zone.

| Property | Detail |
|---|---|
| Grain and key | One row per (`date`, `zone_level`, `residence_district_id`, `overnight_zone_id`). |
| Inputs | [`bronze_mitma_overnight_daily`](bronze_mitma_overnight_daily.md) |
| Transformation | • Cast `fecha` → `DATE` and `personas` → `DOUBLE`.<br>• Rename the source zone codes to English keys.<br>• Keep the source grain: one Bronze row stays one Silver row (no aggregation).<br>[Overnight transformation](../../sql/bronze_to_silver/fact_overnight.sql) |
| Storage | Parquet partitioned by (`zone_level`, `date`). |
| Validation | Checks both zone references and reconciles the row count and total persons to Bronze. [Daily batch loader](../../scripts/lakehouse/mobility.py) |
| Used by | [`gold_overnight_presence`](gold_overnight_presence.md) |

## Columns

One source observation stays one Silver row (the count is preserved from Bronze).

| Column | Type | Description |
|---|---|---|
| `date` | DATE | Night date (from Bronze `fecha`) |
| `zone_level` | VARCHAR | Zoning level of the overnight zone: `distritos`, `municipios` or `GAU` |
| `residence_district_id` | VARCHAR | Where people live, from Bronze `zona_residencia`; always a district. FK → `silver_dim_zone` (`distritos`) |
| `overnight_zone_id` | VARCHAR | Where they slept, from Bronze `zona_pernoctacion`. FK → `silver_dim_zone` at `zone_level` |
| `people` | DOUBLE | Number of people, from Bronze `personas` |

## Inspect the data

```sql
SELECT date, residence_district_id, overnight_zone_id, people
FROM lake.main.silver_fact_overnight
WHERE zone_level = 'distritos' AND date = DATE '2023-03-06'
LIMIT 10;
```

[Table catalog](README.md) · [Silver column contract](../../sql/schema/silver.sql) · [DuckLake layout](../../sql/schema/ducklake.sql)

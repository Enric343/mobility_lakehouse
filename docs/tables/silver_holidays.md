# `silver_holidays`

Published public holidays by autonomous community or city.

| Property | Detail |
|---|---|
| Grain and key | One row per (`date`, `ccaa_code`). |
| Inputs | [`bronze_boe_holidays`](bronze_boe_holidays.md) |
| Transformation | • Keep only cells that carry a holiday mark.<br>• Build a `DATE` from the day, month and year.<br>• Map the BOE region label to its INE community code.<br>[Holiday transformation](../../sql/bronze_to_silver/holidays.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks date and region keys, community references, and reconciliation to marked BOE cells. [Silver reference checks](../../sql/validation/reference_silver.sql) |
| Used by | [`gold_typical_day_patterns`](gold_typical_day_patterns.md) calendar classification and network day labels. |

## Columns

One row per holiday and region. National holidays are the dates observed in all 19 regions. Local holidays that appear only in BOE footnotes are not included.

| Column | Type | Description |
|---|---|---|
| `date` | DATE | Day from `fiesta` + month from `mes` + `year` (PK) |
| `ccaa_code` | VARCHAR | INE community code (PK, FK → `silver_dim_ccaa`). From a hand-written list of the 19 BOE names, since the BOE gives no code |
| `holiday_name` | VARCHAR | `fiesta` without the leading day number |

## Inspect the data

```sql
SELECT date, ccaa_code, holiday_name
FROM lake.main.silver_holidays
ORDER BY date, ccaa_code
LIMIT 10;
```

[Table catalog](README.md) · [Silver column contract](../../sql/schema/silver.sql)

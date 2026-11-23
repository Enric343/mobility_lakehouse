# `gold_runs`

Completion record for each validated Gold window.

| Property | Detail |
|---|---|
| Grain and key | One row per (`period_start`, `period_end`). |
| Inputs | The validated typical-day and gravity outputs for that window. |
| Transformation | Records the model revision and completion timestamp in the transaction that publishes Gold. [Gold builder](../../scripts/lakehouse/gold.py) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Written only after all Gold checks pass. [Gold validation](../../sql/validation/gold.sql) |
| Used by | Gold reuses the validated window for the same model revision. |

## Columns

| Column | Type | Description |
|---|---|---|
| `period_start`, `period_end` | DATE | Completed reporting window |
| `model_revision` | VARCHAR | Gold model revision |
| `completed_at` | TIMESTAMPTZ | Commit time of the validated Gold snapshot |

## Inspect the data

```sql
SELECT period_start, period_end, model_revision, completed_at
FROM lake.main.gold_runs
ORDER BY period_start;
```

[Table catalog](README.md) · [Gold DDL](../../sql/schema/gold.sql)

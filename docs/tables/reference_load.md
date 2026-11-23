# `reference_load`

Completion record for the fixed reference snapshot.

| Property | Detail |
|---|---|
| Grain and key | One row for the loaded `reference_year` in the catalog. |
| Inputs | Validated MITMA, INE and BOE reference loads. |
| Transformation | Records the year and load time within the same transaction as the reference tables. [Reference loader](../../scripts/lakehouse/reference.py) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Written after the reference checks pass. [Bronze reference checks](../../sql/validation/reference_bronze.sql) · [Silver reference checks](../../sql/validation/reference_silver.sql) |
| Used by | Sprint 2 skips the existing 2023 reference snapshot on retries. |

## Columns

| Column | Type | Description |
|---|---|---|
| `reference_year` | INTEGER | Loaded reference year (2023) |
| `loaded_at` | TIMESTAMPTZ | Commit time of the reference snapshot |

## Inspect the data

```sql
SELECT reference_year, loaded_at
FROM lake.main.reference_load;
```

[Table catalog](README.md) · [DuckLake layout](../../sql/schema/ducklake.sql)

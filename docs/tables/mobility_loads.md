# `mobility_loads`

Ledger of committed daily MITMA batches.

| Property | Detail |
|---|---|
| Grain and key | One row per (`dataset`, `zone_level`, `observation_date`). |
| Inputs | Validated daily Bronze and Silver staging tables. |
| Transformation | Records the source file, both row counts, source volume and commit timestamp. [Daily batch loader](../../scripts/lakehouse/mobility.py) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Commits with both layers after batch checks. The key lets retries skip completed inputs. |
| Used by | Sprint 2 retries and Gold input coverage. [Gold builder](../../scripts/lakehouse/gold.py) |

## Columns

| Column | Type | Description |
|---|---|---|
| `dataset` | VARCHAR | `viajes` or `pernoctaciones` |
| `zone_level` | VARCHAR | `distritos`, `municipios`, `GAU` |
| `observation_date` | DATE | Day the batch covers |
| `source_file` | VARCHAR | Source file, relative to the raw inputs |
| `bronze_rows`, `silver_rows` | BIGINT | Row counts on each side |
| `published_total` | DOUBLE | Source volume (trips or people) |
| `loaded_at` | TIMESTAMPTZ | Commit time |

## Inspect the data

```sql
SELECT source_file, bronze_rows, silver_rows, published_total
FROM lake.main.mobility_loads
WHERE dataset = 'viajes' AND zone_level = 'municipios'
  AND observation_date = DATE '2023-03-06';
```

[Table catalog](README.md) · [DuckLake layout](../../sql/schema/ducklake.sql)

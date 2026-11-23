# `bronze_boe_holidays`

The BOE 2023 holiday grid converted to rows.

| Property | Detail |
|---|---|
| Grain and key | One row per year, month, named holiday and BOE region, including unmarked cells. |
| Inputs | BOE XML file `2023_BOE-A-2022-16755.xml`. |
| Transformation | • Unpivot the XML grid to one row per holiday × region.<br>• Add `year` from the file name; keep the month, label, region and mark.<br>[Reference loader](../../scripts/lakehouse/reference.py) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks that the input covers 19 regions and has unique holiday-region cells and valid marks. [Bronze reference checks](../../sql/validation/reference_bronze.sql) |
| Used by | [`silver_holidays`](silver_holidays.md) |

## Columns

One row per holiday × region after unpivoting the XML grid. All columns are `VARCHAR`.

| Column | Description |
|---|---|
| `year` | Added, from the file name (the grid only gives day and month) |
| `mes` | Month (`ENERO`, …) |
| `fiesta` | Day number + holiday name |
| `ccaa` | Region label, with footnote marks |
| `marca` | `*` / `**` / `***`, or empty where it is not a holiday |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT mes, fiesta, ccaa, marca
FROM lake.main.bronze_boe_holidays
WHERE year = '2023' AND marca <> ''
LIMIT 10;
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

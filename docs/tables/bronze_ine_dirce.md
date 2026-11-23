# `bronze_ine_dirce`

Published INE business counts by territorial unit and activity.

| Property | Detail |
|---|---|
| Grain and key | One observation per territorial unit, activity group and year. |
| Inputs | INE DIRCE table `4721`. |
| Transformation | Retains national, provincial and municipal rows and the original number text. [INE ingestion](../../sql/ingestion/ine.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks the 2023 national total and later validates selected municipal activity counts. [Bronze reference checks](../../sql/validation/reference_bronze.sql) |
| Used by | [`silver_zone_metrics`](silver_zone_metrics.md) |

## Columns

All columns are `VARCHAR`. `Totales Territoriales` and `Grupos CNAE` contain spaces, so quote them in SQL.

| Column | Description |
|---|---|
| `Totales Territoriales` | e.g. `Total Nacional` |
| `Provincias` | Empty on the national total |
| `Municipios` | Empty on national and province totals |
| `Grupos CNAE` | 11 activity groups including `Total` |
| `Periodo` | Year |
| `Total` | Spanish number text; empty or `.` means no data |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT Municipios, "Grupos CNAE", Total
FROM lake.main.bronze_ine_dirce
WHERE Periodo = '2023' AND Municipios IS NOT NULL
  AND "Grupos CNAE" = 'Total'
LIMIT 10;
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

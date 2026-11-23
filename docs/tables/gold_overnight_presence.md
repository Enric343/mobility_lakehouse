# `gold_overnight_presence`

A prototype of daily overnight presence and net balance by district.

| Property | Detail |
|---|---|
| Grain and key | One row per (`date`, `district_id`). |
| Inputs | [`silver_fact_overnight`](silver_fact_overnight.md) at district level, created in the Sprint 1 session. |
| Transformation | • Sum people by overnight district and by residence district separately.<br>• Full-join the two sides; a missing side leaves the net balance null.<br>[Prototype SQL](../../sql/silver_to_gold/overnight_presence.sql) |
| Storage | In-memory DuckDB table during Sprint 1. |
| Validation | Checks that totals by date reconcile to the Silver overnight source. [Prototype validation](../../sql/validation/sprint1.sql) |
| Used by | Sprint 1 overnight example. Run the query below in the session that created this prototype table. |

## Columns

Districts observed on either side are kept; the missing side stays null.

| Column | Type | Description |
|---|---|---|
| `date` | DATE | Night date |
| `district_id` | VARCHAR | District on either side of the overnight fact |
| `people_present` | DOUBLE | Published people summed by overnight district |
| `people_by_residence` | DOUBLE | Published people summed by residence district |
| `net_overnight_people` | DOUBLE | Present minus by-residence when both exist |

## Inspect the data

```sql
SELECT date, district_id, people_present, people_by_residence, net_overnight_people
FROM gold_overnight_presence
LIMIT 10;
```

[Table catalog](README.md) · [Sprint 1 runner](../../scripts/run_sprint1.py)

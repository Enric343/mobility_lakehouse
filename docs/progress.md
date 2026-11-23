# Project progress

For architecture and dataset lookup, start with the [lakehouse map](lakehouse.md)
or the [table catalog](tables/README.md). This page records verified milestones.

## Sprint 1 · Schema design and prototyping

Complete for the assignment's schema and SQL proof-of-concept scope.

- Bronze, Silver, and Gold contracts describe sources, grains, keys, and target
  partitioning. Gold covers all three business questions at design level.
- The seven-day proof of concept converts municipal trips and district overnight
  records from CSV-backed Bronze views to typed Silver facts. It then creates
  weekday/weekend OD-hour trip averages and daily district overnight balances.
- The exploration notebook preserves the source, zoning, demographic, and
  holiday findings. The Silver schema notebook uses the shared DuckDB DDL.

### Verification

Ran `python scripts/run_sprint1.py` in DuckDB 1.5.6 with the local files for
2023-03-06 through 2023-03-12. All eight checks passed, covering dates, keys,
measures, row counts, zone references, and conservation of trips and people.

| Result | Rows |
|---|---:|
| `silver_fact_trips` | 33,257,157 |
| `silver_fact_overnight` | 2,744,005 |
| `gold_typical_day_patterns` | 5,571,796 |
| `gold_overnight_presence` | 26,201 |

The Sprint 1 command was rerun after sharing the fact SQL with Sprint 2. The
eight checks passed and all four row counts matched the original run.

## Sprint 2 · DuckLake implementation and ingestion

Complete for the local lakehouse, source ingestion, Bronze checks and initial
Silver tables. `scripts/run_sprint2.py` loads the MITMA, INE and BOE inputs and
reuses the reference snapshot across date ranges. The downloader now extracts the
INE province list from the official page. [Runbook](runbook.md) · [Source inventory](data_sources.md)

### Verification

Loaded all 42 daily files for 2023-03-06 through 2023-03-12 in DuckDB 1.5.6 with
DuckLake. The first day was committed separately, and the week run resumed with
the 36 remaining files. Verified that the persisted counts and published totals
matched every load record. A subsequent run reported 42 already loaded and zero
pending files.

| MITMA facts | Files | Bronze rows | Silver rows |
|---|---:|---:|---:|
| Trips | 21 | 256,082,044 | 115,561,162 |
| Overnight stays | 21 | 6,432,437 | 6,432,437 |

Silver contains 19 autonomous communities and cities, 52 provinces, 8,850 zones,
229 holiday records and 8,348 zone metric rows. All three zoning levels sum to
47,972,964 people. Municipality and GAU each sum to 3,205,679 published DIRCE
businesses. District-level business metrics remain null as designed.

Controlled fixtures verified rollback when the Silver write fails, retry after a
corrected input, missing-file reporting and separate partitions for the same day
number in different months. The local catalog contains the sample week. The full
2023 daily dataset remains to be loaded when needed.

## Sprint 3 · Airflow, Gold and maps

Complete for the two principal business questions on 6–12 March 2023.
`mobility_sprint3` runs download, Bronze/Silver load, validated Gold build,
and publication. The offline HTML report and four PNG figures are in
`data/reports/sprint3/`. [Runbook](runbook.md) · [Analysis guide](sprint3.md)

### Verification

Ran `airflow dags test mobility_sprint3 2023-03-12` twice in Ubuntu WSL2 with
Airflow 3.2.1. Both runs finished with all four tasks successful. The first
reused all 42 Bronze/Silver inputs, built Gold, and passed eight Gold checks.
The second reused the validated Gold snapshot and regenerated all figures.
The DAG took about 2 minutes 45 seconds on the first run and 12 seconds on the
repeat, excluding environment setup. The report embeds all four figures.

| Result | Sample |
|---|---:|
| OD-hour means across three levels and both pattern bases | 39,131,720 |
| Daily assignments | 21 |
| Eligible directed municipal gravity pairs | 6,597,192 |
| Eligible pairs with a published flow | 734,366 (11.1%) |
| Municipality origins with a comparable ratio | 2,563 |

At municipality level, mean daily trips were 139.4 million on weekdays and
115.3 million at the weekend. The weekday profile peaked at 14:00 and the
weekend profile at 13:00. K-means recovered that same five/two split at all
three levels. There were no holidays in the sample.

The fitted gravity coefficient was approximately 0.0119085. Of the 2,563
ranked origins, 194 had fewer observed trips than estimated for the pairs with
a published flow. Pair coverage is included alongside each ratio. [Analysis guide](sprint3.md)

## Next · Sprint 4

- Move the validated DAG tasks to AWS Batch and review the resulting cloud run.
- Address feedback on the Gold analyses. The overnight question remains
  available as a Sprint 1 prototype. [Lakehouse map](lakehouse.md)

# Sprint 3 analysis guide

The sample window is 6–12 March 2023. Open `data/reports/sprint3/index.html` for
the results and maps. The report is self-contained and uses the MITMA zone
polygons already stored in Silver. The PNGs in the same folder can be reused
in slides or the project article.

## BQ1 · Typical mobility day

1. `daily_od.sql` sums the published Silver facts to day, hour, and directed OD
   pair. It processes one zoning level at a time.
2. `classify_origins.sql` gives a regional holiday priority over weekend and
   weekday. The network profile uses a national holiday when all 19 regions
   observe it. The sample contains five weekdays and two weekend days.
3. `clustering.py` fits two reproducible k-means groups for each of the three
   zoning levels. Each observation is a day represented by its 24 hourly shares
   of daily trips. Cluster 1 has the lower mean daily trip volume.
4. Gold publishes OD matrices and network profiles by calendar type and by
   cluster. It also publishes daily labels and average daily origin volumes.
   `observed_days` is the denominator for each mean. Use one pattern basis per
   query because both describe the same trips.

The map shows percentage change in mean published trips originating in each
MITMA municipal zone on weekend days versus weekdays. The report's hourly
curves use network totals, which have a common daily denominator. Each OD cell
can have its own denominator, so the network curve comes from its own aggregate.

## BQ2 · Gravity model and gaps

The directed candidate pairs use domestic municipality zones, with positive
origin population and positive destination business counts. Same-zone pairs and
zero-distance centroids are outside the candidate set. The SQL transforms the
MITMA centroids from EPSG:3042 and computes great-circle distance in kilometres.

For `weight = population × businesses / distance_km²`, the fit is
`k = sum(published trips) / sum(weight)` over the eligible published pairs.
The estimate is `k × weight`. A candidate pair with no published flow has a
prediction and an unknown actual value. Calibration and ratios use observations.

The origin ranking divides total observed trips by total estimated trips over
the same observed pairs. This weights each pair through the gravity estimate.
Pair coverage is the share of eligible destinations with a published flow. It
is 9.4% at the median ranked origin. A pair's actual volume sums the days with
a published value. Of the 734,366 observed pairs, 338,493 (46.1%) appear on one
day and 123,594 (16.8%) appear on all seven. The maps and ratios are exploratory
because censoring, business counts and centroid distances can all influence
the ranking. Attributing a gap to transport infrastructure needs independent
evidence.

## Follow the work in the repository

| Step | Code |
|---|---|
| Sequence the sample tasks | `dags/mobility_sprint3.py` |
| Prepare and publish Gold atomically | `scripts/lakehouse/gold.py` |
| Read the business logic | `sql/silver_to_gold/` |
| Check coverage, reconcile volumes, and validate the fitted model | `sql/validation/gold.sql` |
| Read Gold and render the figures | `sql/reporting/sprint3.sql` and `scripts/reporting/` |

[Run the pipeline](runbook.md#run-sprint-3) · [Gold table cards](tables/README.md#gold) · [Verification](progress.md)

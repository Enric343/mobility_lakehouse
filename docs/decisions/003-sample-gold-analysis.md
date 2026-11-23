# 003. Publish sample-week Gold by calendar, cluster, and comparable gravity pair

## Context

Sprint 3 needs two complete Gold analyses with maps and a reproducible Airflow
run. The review scope is the seven loaded sample days. MITMA publishes only
some directed OD-hours and pairs, which affects comparisons and calibration.

## Decision

Build the sample Gold window from the existing Silver data. Store both the
calendar and two-cluster OD results, with their observed day counts. Fit one
municipality gravity coefficient by matching volume over eligible published
pairs. Rank origins by their volume ratio on those same pairs and expose
pair coverage. Publish the Gold tables and completion record in one transaction.

## Alternatives considered

- Treat missing flows as zero. This simplifies averaging and ranking and makes
  published coverage affect the demand score directly.
- Use only weekday and weekend categories. This supports calendar interpretation
  and leaves the assignment's clustering question unanswered.
- Load the full reference year for the first Gold review. This would support
  holiday calibration and seasonality and exceeds the agreed test window.

## Consequences

The two pattern bases provide complementary summaries of the same volume.
Consumers select a basis and read the denominator with each mean. Gravity
estimates cover the eligible pairs, and comparable scores cover published pairs.
The sample covers weekday and weekend shapes. Holiday and annual conclusions
would need additional observations. Local Airflow runs tasks sequentially so
the embedded DuckLake catalog has one writer at a time.

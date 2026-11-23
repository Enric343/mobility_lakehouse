# Table catalog

Each page describes one table's grain, provenance, transformations, persistence,
validation, columns and a short query. The persisted tables are in `lake.main`.
Attach the sample catalog read-only before running the examples. [Query setup](../runbook.md#query-the-local-lakehouse)

For all tables grouped by layer at a glance, open the
[overview diagram (draw.io)](../diagrams/schemas/tables_overview.drawio). Per-layer schema
diagrams with every column and type are in the [diagrams index](../diagrams/README.md).

## Bronze

- [`bronze_mitma_od_daily`](bronze_mitma_od_daily.md). Published daily trip flows as delivered by MITMA.
- [`bronze_mitma_overnight_daily`](bronze_mitma_overnight_daily.md). Published overnight counts by residence and sleeping location.
- [`bronze_mitma_zone_names`](bronze_mitma_zone_names.md). Names attached to MITMA zone identifiers.
- [`bronze_mitma_zone_geometries`](bronze_mitma_zone_geometries.md). The spatial features of MITMA zones.
- [`bronze_mitma_zone_mapping`](bronze_mitma_zone_mapping.md). Correspondence between INE census geography and MITMA zones.
- [`bronze_ine_adrh`](bronze_ine_adrh.md). Published INE Atlas of Household Income indicators in source format.
- [`bronze_ine_dirce`](bronze_ine_dirce.md). Published INE business counts by territorial unit and activity.
- [`bronze_ine_provinces`](bronze_ine_provinces.md). The official province list with community codes.
- [`bronze_boe_holidays`](bronze_boe_holidays.md). The BOE 2023 holiday grid converted to rows.

## Silver

- [`silver_fact_trips`](silver_fact_trips.md). Typed and aggregated trip flows by OD-hour and activity.
- [`silver_fact_overnight`](silver_fact_overnight.md). Typed person counts by residence district and sleeping zone.
- [`silver_dim_ccaa`](silver_dim_ccaa.md). Autonomous communities and cities used in administrative and calendar joins.
- [`silver_dim_province`](silver_dim_province.md). Province keys, names and parent communities.
- [`silver_dim_zone`](silver_dim_zone.md). Shared geography for mobility, metrics and maps.
- [`silver_holidays`](silver_holidays.md). Published public holidays by autonomous community or city.
- [`silver_zone_metrics`](silver_zone_metrics.md). 2023 population, income and business metrics by MITMA zone.

## Gold

- [`gold_typical_day_patterns`](gold_typical_day_patterns.md). Typical hourly OD matrices by calendar day type or fitted cluster.
- [`gold_day_assignments`](gold_day_assignments.md). Daily network summaries and their calendar and cluster labels.
- [`gold_hourly_demand`](gold_hourly_demand.md). Average hourly network demand by calendar type or fit cluster.
- [`gold_origin_demand`](gold_origin_demand.md). Average daily trips departing each zone by calendar day type.
- [`gold_infrastructure_gaps`](gold_infrastructure_gaps.md). Observed and estimated weekly trips for eligible directed municipality pairs.
- [`gold_gravity_zone_ranking`](gold_gravity_zone_ranking.md). Gravity comparison and publication coverage by municipality origin.
- [`gold_gravity_calibration`](gold_gravity_calibration.md). Fitted multiplier and evidence for the municipality gravity model.

## Load tracking

- [`mobility_loads`](mobility_loads.md). Ledger of committed daily MITMA batches.
- [`reference_load`](reference_load.md). Completion record for the fixed reference snapshot.
- [`gold_runs`](gold_runs.md). Completion record for each validated Gold window.

## Sprint 1 prototype

- [`gold_overnight_presence`](gold_overnight_presence.md). A prototype of daily overnight presence and net balance by district.

[Lakehouse map](../lakehouse.md) · [Schema overview](../lakehouse.md#schema-overview) · [Bronze to Silver guide](../bronze-to-silver.md)

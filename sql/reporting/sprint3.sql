CREATE TEMP VIEW report_days AS
SELECT zone_level, date, day_type, cluster_id, total_trips, peak_hour
FROM lake.main.gold_day_assignments
WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end');

CREATE TEMP VIEW report_hourly AS
SELECT zone_level, pattern_basis, pattern, hour_of_day, avg_hourly_trips, observed_days
FROM lake.main.gold_hourly_demand
WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end');

CREATE TEMP VIEW report_fit AS
SELECT gravity_k, eligible_pairs, observed_pairs, observed_trips
FROM lake.main.gold_gravity_calibration
WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end');

CREATE TEMP VIEW report_ranking AS
SELECT r.origin_zone_id, z.zone_name, r.origin_population, r.service_ratio, r.pair_coverage,
       r.actual_trips, r.estimated_on_observed_pairs, r.gap_rank
FROM lake.main.gold_gravity_zone_ranking r
JOIN lake.main.silver_dim_zone z ON z.zone_level = r.zone_level AND z.zone_id = r.origin_zone_id
WHERE r.period_start = getvariable('gold_start') AND r.period_end = getvariable('gold_end');

CREATE TEMP VIEW report_map AS
WITH origin_demand AS (
    SELECT origin_zone_id,
           max(avg_daily_trips) FILTER (WHERE day_type = 'weekday') AS weekday_trips,
           max(avg_daily_trips) FILTER (WHERE day_type = 'weekend') AS weekend_trips
    FROM lake.main.gold_origin_demand
    WHERE zone_level = 'municipios'
      AND period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
    GROUP BY origin_zone_id
)
SELECT z.zone_id, z.province_code,
       ST_AsGeoJSON(ST_SimplifyPreserveTopology(z.geom, 80.0)) AS geometry,
       o.weekend_trips / nullif(o.weekday_trips, 0) - 1 AS weekend_change,
       r.service_ratio
FROM lake.main.silver_dim_zone z
LEFT JOIN origin_demand o ON o.origin_zone_id = z.zone_id
LEFT JOIN report_ranking r ON r.origin_zone_id = z.zone_id
WHERE z.zone_level = 'municipios' AND NOT z.is_foreign AND z.geom IS NOT NULL;

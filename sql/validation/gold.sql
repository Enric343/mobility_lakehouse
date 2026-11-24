WITH trip_loads AS (
    SELECT zone_level, observation_date AS date, published_total
    FROM lake.main.mobility_loads
    WHERE dataset = 'viajes' AND observation_date BETWEEN getvariable('gold_start') AND getvariable('gold_end')
), expected AS (
    SELECT zone_level, sum(published_total) AS trips, count(*) AS days
    FROM trip_loads
    GROUP BY zone_level
), od AS (
    SELECT zone_level, pattern_basis, sum(avg_hourly_trips * observed_days) AS trips
    FROM lake.main.gold_typical_day_patterns
    WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
    GROUP BY zone_level, pattern_basis
), origins AS (
    SELECT zone_level, sum(avg_daily_trips * observed_days) AS trips
    FROM lake.main.gold_origin_demand
    WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
    GROUP BY zone_level
), profiles AS (
    SELECT zone_level, pattern_basis, sum(avg_hourly_trips * observed_days) AS trips
    FROM lake.main.gold_hourly_demand
    WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
    GROUP BY zone_level, pattern_basis
), daily AS (
    SELECT zone_level, date, day_type, cluster_id, total_trips, peak_hour
    FROM lake.main.gold_day_assignments
    WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
), labels AS (
    SELECT zone_level, count(*) AS rows, count(DISTINCT date) AS days, count(DISTINCT cluster_id) AS clusters
    FROM daily
    GROUP BY zone_level
), fit AS (
    SELECT * FROM lake.main.gold_gravity_calibration
    WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
), gaps AS (
    SELECT * FROM lake.main.gold_infrastructure_gaps
    WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
), gap_totals AS (
    SELECT count(*) AS pairs, count(actual_trips) AS published_pairs, sum(actual_trips) AS actual,
           sum(estimated_trips) FILTER (WHERE actual_trips IS NOT NULL) AS estimated,
           count(*) - count(DISTINCT (origin_zone_id, destination_zone_id)) AS duplicate_pairs,
           count(*) FILTER (WHERE (actual_trips IS NULL) <> (actual_to_estimated_ratio IS NULL)
               OR zone_level IS DISTINCT FROM 'municipios'
               OR origin_zone_id IS NULL OR destination_zone_id IS NULL OR origin_zone_id = destination_zone_id
               OR NOT coalesce(isfinite(distance_km) AND distance_km > 0, false)
               OR NOT coalesce(isfinite(estimated_trips) AND estimated_trips > 0, false)
               OR (actual_trips IS NOT NULL AND (
                   NOT isfinite(actual_trips) OR actual_trips < 0 OR NOT isfinite(actual_to_estimated_ratio)
                   OR abs(actual_to_estimated_ratio - actual_trips / estimated_trips)
                       > greatest(1e-10, abs(actual_to_estimated_ratio) * 1e-10)
               ))) AS invalid_rows
    FROM gaps
), rankings AS (
    SELECT * FROM lake.main.gold_gravity_zone_ranking
    WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
), ranking_totals AS (
    SELECT sum(eligible_pairs) AS eligible_pairs, sum(observed_pairs) AS observed_pairs,
           sum(actual_trips) AS actual, sum(estimated_on_observed_pairs) AS estimated
    FROM rankings
)
SELECT 'Gold calendar and cluster OD averages preserve all published trips' AS check_name, count(*) AS issues
FROM expected e CROSS JOIN (VALUES ('calendar'), ('cluster')) b(pattern_basis)
LEFT JOIN od ON od.zone_level = e.zone_level AND od.pattern_basis = b.pattern_basis
WHERE od.trips IS NULL OR abs(od.trips - e.trips) > greatest(0.001, e.trips * 1e-10)
UNION ALL
SELECT 'Gold origin averages preserve all published trips', count(*)
FROM expected e LEFT JOIN origins USING (zone_level)
WHERE origins.trips IS NULL OR abs(origins.trips - e.trips) > greatest(0.001, e.trips * 1e-10)
UNION ALL
SELECT 'Gold calendar and cluster hourly profiles preserve all published trips', count(*)
FROM expected e CROSS JOIN (VALUES ('calendar'), ('cluster')) b(pattern_basis)
LEFT JOIN profiles p ON p.zone_level = e.zone_level AND p.pattern_basis = b.pattern_basis
WHERE p.trips IS NULL OR abs(p.trips - e.trips) > greatest(0.001, e.trips * 1e-10)
UNION ALL
SELECT 'Gold assigns each published day exactly once and finds two clusters per level', count(*)
FROM expected e LEFT JOIN labels l USING (zone_level)
WHERE l.rows IS DISTINCT FROM e.days OR l.days IS DISTINCT FROM e.days OR l.clusters IS DISTINCT FROM 2
UNION ALL
SELECT 'Gold daily assignments match each Silver trip load and use valid labels', count(*)
FROM trip_loads t FULL JOIN daily d USING (zone_level, date)
WHERE t.date IS NULL OR d.date IS NULL
   OR NOT coalesce(d.day_type IN ('weekday', 'weekend', 'holiday')
       AND d.cluster_id IN (1, 2) AND d.peak_hour BETWEEN 0 AND 23
       AND isfinite(d.total_trips) AND d.total_trips > 0
       AND abs(d.total_trips - t.published_total) <= greatest(0.001, t.published_total * 1e-10), false)
UNION ALL
SELECT 'Gravity estimates use valid pairs and preserve unknown observed demand', invalid_rows FROM gap_totals
UNION ALL
SELECT 'Gravity directed pair keys are unique', duplicate_pairs FROM gap_totals
UNION ALL
SELECT 'Gravity calibration uses the observed eligible pairs and matches their volume', count(*)
FROM gap_totals g LEFT JOIN fit f ON true
WHERE (SELECT count(*) FROM fit) <> 1 OR f.zone_level IS DISTINCT FROM 'municipios'
   OR f.gravity_k IS NULL OR NOT isfinite(f.gravity_k) OR f.gravity_k <= 0 OR g.published_pairs = 0
   OR g.pairs IS DISTINCT FROM f.eligible_pairs OR g.published_pairs IS DISTINCT FROM f.observed_pairs
   OR NOT coalesce(abs(g.actual - f.observed_trips) <= greatest(0.001, g.actual * 1e-10)
       AND abs(g.estimated - f.estimated_on_observed_pairs) <= greatest(0.001, g.estimated * 1e-10)
       AND abs(g.estimated - g.actual) <= greatest(0.001, g.actual * 1e-10), false)
UNION ALL
SELECT 'Gravity origin rankings preserve the comparable observed quantities', count(*)
FROM gap_totals g CROSS JOIN ranking_totals r
WHERE g.pairs IS DISTINCT FROM r.eligible_pairs OR g.published_pairs IS DISTINCT FROM r.observed_pairs
   OR NOT coalesce(abs(g.actual - r.actual) <= greatest(0.001, g.actual * 1e-10)
       AND abs(g.estimated - r.estimated) <= greatest(0.001, g.estimated * 1e-10), false)
UNION ALL
SELECT 'Gravity origins and assigned ranks are unique', count(*) - count(DISTINCT origin_zone_id)
    + count(gap_rank) - count(DISTINCT gap_rank)
FROM rankings;

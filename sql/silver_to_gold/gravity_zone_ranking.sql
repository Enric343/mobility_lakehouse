-- Divide volumes on comparable observed pairs. Summing the gravity estimate
-- weights each pair by origin population, destination businesses and distance.
WITH origin_totals AS (
    SELECT zone_level, origin_zone_id, any_value(origin_population) AS origin_population,
           count(*) AS eligible_pairs, count(actual_trips) AS observed_pairs,
           count(actual_trips)::DOUBLE / count(*) AS pair_coverage,
           sum(actual_trips) AS actual_trips,
           sum(estimated_trips) FILTER (WHERE actual_trips IS NOT NULL) AS estimated_on_observed_pairs
    FROM lake.main.gold_infrastructure_gaps
    WHERE period_start = getvariable('gold_start') AND period_end = getvariable('gold_end')
    GROUP BY zone_level, origin_zone_id
), scores AS (
    SELECT *, actual_trips / nullif(estimated_on_observed_pairs, 0) AS service_ratio
    FROM origin_totals
)
SELECT *, CASE WHEN service_ratio IS NOT NULL THEN
    row_number() OVER (ORDER BY service_ratio NULLS LAST, origin_zone_id)
END AS gap_rank
FROM scores;

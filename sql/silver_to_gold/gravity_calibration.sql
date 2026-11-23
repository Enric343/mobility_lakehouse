-- Fit k by matching published volume over the model-eligible observed pairs.
-- Unobserved pairs participate in predictions and stay out of calibration.
CREATE OR REPLACE TEMP TABLE gravity_fit AS
WITH totals AS (
    SELECT count(*) AS eligible_pairs,
           count(actual_trips) AS observed_pairs,
           sum(actual_trips) AS observed_trips,
           sum(weight) FILTER (WHERE actual_trips IS NOT NULL) AS observed_weight
    FROM gravity_candidates
)
SELECT 'municipios' AS zone_level,
       observed_trips / nullif(observed_weight, 0) AS gravity_k,
       eligible_pairs, observed_pairs, observed_trips,
       observed_weight * gravity_k AS estimated_on_observed_pairs
FROM totals;

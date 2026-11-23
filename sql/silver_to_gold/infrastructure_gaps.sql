SELECT f.zone_level, c.origin_zone_id, c.destination_zone_id, c.origin_population,
       c.destination_businesses, c.distance_km, c.actual_trips,
       f.gravity_k * c.weight AS estimated_trips,
       c.actual_trips / nullif(f.gravity_k * c.weight, 0) AS actual_to_estimated_ratio
FROM gravity_candidates c CROSS JOIN gravity_fit f;

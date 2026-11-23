SELECT
    zone_level,
    pattern_basis,
    day_type,
    hour_of_day,
    origin_zone_id,
    destination_zone_id,
    AVG(trips) AS avg_hourly_trips,
    COUNT(*) AS observed_days
FROM patterned_od
GROUP BY zone_level, pattern_basis, day_type, hour_of_day, origin_zone_id, destination_zone_id;

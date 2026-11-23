WITH profiles AS (
    SELECT p.*, d.day_type, d.cluster_id
    FROM daily_profiles p JOIN daily_labels d USING (zone_level, date)
)
SELECT zone_level, pattern_basis, pattern, hour_of_day,
       avg(trips) AS avg_hourly_trips, count(*) AS observed_days
FROM profiles
CROSS JOIN LATERAL (VALUES ('calendar', day_type), ('cluster', 'cluster_' || cluster_id::VARCHAR)) labels(pattern_basis, pattern)
GROUP BY zone_level, pattern_basis, pattern, hour_of_day;

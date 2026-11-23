WITH origin_days AS (
    SELECT zone_level, origin_zone_id, date, day_type, sum(trips) AS trips
    FROM classified_od GROUP BY zone_level, origin_zone_id, date, day_type
)
SELECT zone_level, origin_zone_id, day_type, avg(trips) AS avg_daily_trips, count(*) AS observed_days
FROM origin_days GROUP BY zone_level, origin_zone_id, day_type;

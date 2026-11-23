SELECT zone_level, trip_datetime::DATE AS date, hour(trip_datetime) AS hour_of_day,
       origin_zone_id, destination_zone_id, sum(trips) AS trips
FROM query_table($source_table)
WHERE zone_level = $level
  AND trip_datetime >= getvariable('gold_start')::TIMESTAMP
  AND trip_datetime < getvariable('gold_end')::TIMESTAMP + INTERVAL 1 DAY
GROUP BY zone_level, date, hour_of_day, origin_zone_id, destination_zone_id;

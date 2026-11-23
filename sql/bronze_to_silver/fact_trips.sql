SELECT strptime(fecha || periodo, '%Y%m%d%H') AS trip_datetime, zone_level,
       origen AS origin_zone_id, destino AS destination_zone_id,
       actividad_origen AS origin_activity, actividad_destino AS destination_activity,
       SUM(viajes::DOUBLE) AS trips
FROM query_table($source_table)
GROUP BY ALL;

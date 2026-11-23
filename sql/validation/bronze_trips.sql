WITH zones_seen AS (
    SELECT DISTINCT origen AS zone_id FROM daily_bronze
    UNION
    SELECT DISTINCT destino AS zone_id FROM daily_bronze
), zone_errors AS (
    SELECT count(*) AS issues FROM zones_seen
    ANTI JOIN (SELECT zone_id FROM lake.main.silver_dim_zone WHERE zone_level = $level) USING (zone_id)
)
SELECT count(*) AS row_count, sum(try_cast(viajes AS DOUBLE)) AS total,
       count(*) FILTER (WHERE fecha IS DISTINCT FROM $day
           OR NOT coalesce(regexp_full_match(periodo, '[01][0-9]|2[0-3]'), false)
           OR coalesce(trim(actividad_origen), '') = '' OR coalesce(trim(actividad_destino), '') = ''
           OR NOT coalesce(isfinite(try_cast(viajes AS DOUBLE)) AND try_cast(viajes AS DOUBLE) >= 0, false)
           OR NOT coalesce(isfinite(try_cast(viajes_km AS DOUBLE)) AND try_cast(viajes_km AS DOUBLE) >= 0, false)) AS invalid_rows,
       count(*) - count(DISTINCT (periodo, origen, destino, distancia, actividad_origen, actividad_destino,
           estudio_origen_posible, estudio_destino_posible, residencia, renta, edad, sexo)) AS duplicate_rows,
       (SELECT issues FROM zone_errors) AS unknown_zone_ids
FROM daily_bronze;

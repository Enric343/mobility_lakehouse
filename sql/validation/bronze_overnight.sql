WITH zones_seen AS (
    SELECT DISTINCT 'distritos' AS zone_level, zona_residencia AS zone_id FROM daily_bronze
    UNION
    SELECT DISTINCT $level, zona_pernoctacion FROM daily_bronze
), zone_errors AS (
    SELECT count(*) AS issues FROM zones_seen
    ANTI JOIN lake.main.silver_dim_zone USING (zone_level, zone_id)
)
SELECT count(*) AS row_count, sum(try_cast(personas AS DOUBLE)) AS total,
       count(*) FILTER (WHERE fecha IS DISTINCT FROM $day
           OR NOT coalesce(isfinite(try_cast(personas AS DOUBLE)) AND try_cast(personas AS DOUBLE) >= 0, false)) AS invalid_rows,
       count(*) - count(DISTINCT (zona_residencia, zona_pernoctacion)) AS duplicate_rows,
       (SELECT issues FROM zone_errors) AS unknown_zone_ids
FROM daily_bronze;

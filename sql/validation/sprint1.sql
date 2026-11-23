-- Each result row counts problems in one sample-week check. Zero means pass.
WITH expected_dates AS (
    SELECT day::DATE AS date
    FROM generate_series(getvariable('sample_start'), getvariable('sample_end'), INTERVAL 1 DAY) AS dates(day)
), expected_inputs AS (
    SELECT dataset, date FROM (VALUES ('trips'), ('overnight')) AS sources(dataset) CROSS JOIN expected_dates
), bronze_by_day AS (
    SELECT
        'trips' AS dataset,
        try_strptime(fecha, '%Y%m%d')::DATE AS date,
        count(*) AS row_count,
        sum(viajes::DOUBLE) AS total,
        count(*) FILTER (WHERE
            fecha IS DISTINCT FROM split_part(parse_filename(_source_file), '_', 1)
            OR periodo IS NULL OR NOT regexp_full_match(periodo, '[01][0-9]|2[0-3]')
            OR coalesce(trim(origen), '') = '' OR coalesce(trim(destino), '') = ''
            OR coalesce(trim(actividad_origen), '') = '' OR coalesce(trim(actividad_destino), '') = ''
            OR viajes IS NULL OR NOT isfinite(viajes::DOUBLE) OR viajes::DOUBLE < 0
        ) AS invalid_rows
    FROM bronze_mitma_od_daily
    GROUP BY 1, 2
    UNION ALL
    SELECT
        'overnight',
        try_strptime(fecha, '%Y%m%d')::DATE,
        count(*),
        sum(personas::DOUBLE),
        count(*) FILTER (WHERE
            fecha IS DISTINCT FROM split_part(parse_filename(_source_file), '_', 1)
            OR coalesce(trim(zona_residencia), '') = '' OR coalesce(trim(zona_pernoctacion), '') = ''
            OR personas IS NULL OR NOT isfinite(personas::DOUBLE) OR personas::DOUBLE < 0
        )
    FROM bronze_mitma_overnight_daily
    GROUP BY 1, 2
), silver_by_day AS (
    SELECT 'trips' AS dataset, trip_datetime::DATE AS date, count(*) AS row_count, sum(trips) AS total
    FROM silver_fact_trips GROUP BY 1, 2
    UNION ALL
    SELECT 'overnight', date, count(*), sum(people) FROM silver_fact_overnight GROUP BY 1, 2
), zones_in_facts AS (
    SELECT zone_level, origin_zone_id AS zone_id FROM silver_fact_trips
    UNION SELECT zone_level, destination_zone_id FROM silver_fact_trips
    UNION SELECT 'distritos', residence_district_id FROM silver_fact_overnight
    UNION SELECT zone_level, overnight_zone_id FROM silver_fact_overnight
), gold_overnight_by_day AS (
    SELECT date, sum(people_present) AS present, sum(people_by_residence) AS by_residence
    FROM gold_overnight_presence GROUP BY date
), gold_trip_total AS (
    SELECT sum(avg_hourly_trips * observed_days) AS total FROM gold_typical_day_patterns
), silver_trip_total AS (
    SELECT sum(total) AS total FROM silver_by_day WHERE dataset = 'trips'
)
SELECT 'Bronze dates match sample coverage' AS check_name, count(*) AS issues
FROM expected_inputs AS e FULL JOIN bronze_by_day AS b USING (dataset, date)
WHERE e.date IS NULL OR b.date IS NULL
UNION ALL
SELECT 'Source dates, keys and measures are valid', coalesce(sum(invalid_rows), 0)::BIGINT FROM bronze_by_day
UNION ALL
SELECT 'Bronze to Silver row counts match each grain', count(*)
FROM bronze_by_day AS b FULL JOIN silver_by_day AS s USING (dataset, date)
WHERE b.row_count IS NULL OR s.row_count IS NULL
    OR (b.dataset = 'trips' AND s.row_count > b.row_count)
    OR (b.dataset = 'overnight' AND s.row_count <> b.row_count)
UNION ALL
SELECT 'Bronze to Silver conserves daily trips and people', count(*)
FROM bronze_by_day AS b FULL JOIN silver_by_day AS s USING (dataset, date)
WHERE b.total IS NULL OR s.total IS NULL OR abs(b.total - s.total) > greatest(0.001, abs(b.total) * 1e-10)
UNION ALL
SELECT 'Silver overnight keys are unique',
    count(*) - count(DISTINCT (date, zone_level, residence_district_id, overnight_zone_id))
FROM silver_fact_overnight
UNION ALL
SELECT 'Silver zone IDs match the catalog at their own level', count(*)
FROM zones_in_facts ANTI JOIN sample_zone_keys USING (zone_level, zone_id)
UNION ALL
SELECT 'Gold trip averages conserve totals when weighted by observed days', count(*)
FROM silver_trip_total AS s CROSS JOIN gold_trip_total AS g
WHERE s.total IS NULL OR g.total IS NULL OR abs(s.total - g.total) > greatest(0.001, abs(s.total) * 1e-10)
UNION ALL
SELECT 'Gold overnight arrival and residence totals match Silver by date', count(*)
FROM (SELECT date, total FROM silver_by_day WHERE dataset = 'overnight') AS s
FULL JOIN gold_overnight_by_day AS g USING (date)
WHERE s.total IS NULL OR g.present IS NULL OR g.by_residence IS NULL
    OR abs(s.total - g.present) > greatest(0.001, abs(s.total) * 1e-10)
    OR abs(s.total - g.by_residence) > greatest(0.001, abs(s.total) * 1e-10);

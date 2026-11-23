CREATE OR REPLACE TEMP VIEW classified_od AS
WITH dates AS (
    SELECT value::DATE AS date
    FROM generate_series(getvariable('gold_start'), getvariable('gold_end'), INTERVAL 1 DAY) AS days(value)
), origin_days AS (
    SELECT z.zone_level, z.zone_id AS origin_zone_id, d.date,
           mobility_day_type(d.date, h.ccaa_code IS NOT NULL) AS day_type
    FROM lake.main.silver_dim_zone z
    CROSS JOIN dates d
    LEFT JOIN lake.main.silver_dim_province p USING (province_code)
    LEFT JOIN lake.main.silver_holidays h ON h.ccaa_code = p.ccaa_code AND h.date = d.date
    WHERE z.zone_level = getvariable('gold_level')
)
SELECT od.*, c.day_type
FROM daily_od od
JOIN origin_days c USING (zone_level, date, origin_zone_id);

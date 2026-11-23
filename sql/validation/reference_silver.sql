WITH levels(zone_level) AS (VALUES ('distritos'), ('municipios'), ('GAU')),
population_source AS (SELECT sum(population) AS total FROM ine_section_values),
population_by_level AS (SELECT zone_level, sum(population) AS total FROM lake.main.silver_zone_metrics GROUP BY zone_level),
dirce_source AS (SELECT activity, sum(businesses) AS total FROM dirce_municipal_values GROUP BY activity),
businesses_by_level AS (
    SELECT zone_level, activity, sum(businesses) AS total
    FROM lake.main.silver_zone_metrics m
    CROSS JOIN LATERAL (VALUES ('Total', m.businesses_total), ('Industria', m.businesses_industry),
        ('F Construcción', m.businesses_construction), ('Comercio, transporte y hostelería', m.businesses_trade_transport_hospitality),
        ('Total servicios', m.businesses_services)) b(activity, businesses)
    WHERE zone_level IN ('municipios', 'GAU')
    GROUP BY zone_level, activity
)
SELECT 'Silver communities and provinces have unique keys' AS check_name,
       (SELECT count(*) - count(DISTINCT ccaa_code) FROM lake.main.silver_dim_ccaa)
       + count(*) - count(DISTINCT province_code) AS issues
FROM lake.main.silver_dim_province
UNION ALL
SELECT 'Silver provinces link to communities', count(*)
FROM lake.main.silver_dim_province ANTI JOIN lake.main.silver_dim_ccaa USING (ccaa_code)
UNION ALL
SELECT 'Silver zone keys are unique and geometries are present where applicable',
       count(*) - count(DISTINCT (zone_level, zone_id))
       + count(*) FILTER (WHERE coalesce(trim(zone_id), '') = '' OR coalesce(trim(zone_name), '') = ''
           OR (zone_id <> 'externo' AND (geom IS NULL OR centroid IS NULL)))
FROM lake.main.silver_dim_zone
UNION ALL
SELECT 'Silver populated zones link to valid provinces', count(*)
FROM lake.main.silver_dim_zone z LEFT JOIN lake.main.silver_dim_province p USING (province_code)
WHERE z.province_code IS NOT NULL AND p.province_code IS NULL
UNION ALL
SELECT 'Silver holidays have unique dates/regions and preserve each published holiday',
       count(*) - count(DISTINCT (date, ccaa_code))
       + count(*) FILTER (WHERE date IS NULL OR c.ccaa_code IS NULL OR coalesce(trim(holiday_name), '') = '')
       + abs(count(*) - (SELECT count(*) FROM lake.main.bronze_boe_holidays WHERE marca <> ''))
FROM lake.main.silver_holidays h LEFT JOIN lake.main.silver_dim_ccaa c USING (ccaa_code)
UNION ALL
SELECT 'INE section indicators have valid keys and no duplicate observations',
       count(*) - count(DISTINCT (section_id, metric))
       + count(*) FILTER (WHERE NOT regexp_full_match(section_id, '[0-9]{10}') OR (metric = 'population' AND value < 0))
FROM ine_section_indicators
UNION ALL
SELECT 'INE publishes values for all eight selected census-section indicators',
       abs(count(DISTINCT metric) FILTER (WHERE value IS NOT NULL) - 8)
FROM ine_section_indicators
UNION ALL
SELECT 'INE populated sections each map to one valid zone at every level', count(*)
FROM (
    SELECT v.section_id, l.zone_level
    FROM ine_section_values v CROSS JOIN levels l
    LEFT JOIN section_zones s ON s.section_id = v.section_id AND s.zone_level = l.zone_level
    LEFT JOIN lake.main.silver_dim_zone z ON z.zone_level = s.zone_level AND z.zone_id = s.zone_id
    WHERE v.population IS NOT NULL
    GROUP BY v.section_id, l.zone_level HAVING count(z.zone_id) <> 1 OR count(s.section_id) <> 1
)
UNION ALL
SELECT 'Silver metrics have unique keys and valid zone references',
       count(*) - count(DISTINCT (m.zone_level, m.zone_id)) + count(*) FILTER (WHERE z.zone_id IS NULL OR m.population IS NULL)
FROM lake.main.silver_zone_metrics m LEFT JOIN lake.main.silver_dim_zone z USING (zone_level, zone_id)
UNION ALL
SELECT 'Silver conserves the INE reference-year population at every level', count(*)
FROM levels CROSS JOIN population_source s LEFT JOIN population_by_level p USING (zone_level)
WHERE s.total IS DISTINCT FROM 47972964 OR p.total IS DISTINCT FROM s.total
UNION ALL
SELECT 'DIRCE counts are nonnegative integers and unique per municipality and activity',
       count(*) - count(DISTINCT (municipality_ine, activity))
       + count(*) FILTER (WHERE NOT regexp_full_match(municipality_ine, '[0-9]{5}')
           OR businesses < 0 OR businesses <> trunc(businesses))
FROM dirce_municipal_values
UNION ALL
SELECT 'DIRCE publishes counts for all five selected activities',
       abs(count(DISTINCT activity) FILTER (WHERE businesses IS NOT NULL) - 5)
FROM dirce_municipal_values
UNION ALL
SELECT 'Published DIRCE municipalities each map to one MITMA municipality and GAU', count(*)
FROM (
    SELECT d.municipality_ine FROM (SELECT DISTINCT municipality_ine FROM dirce_municipal_values WHERE businesses IS NOT NULL) d
    LEFT JOIN business_municipality_map b ON b.municipio_ine = d.municipality_ine
    GROUP BY d.municipality_ine HAVING count(b.municipio_ine) <> 1
)
UNION ALL
SELECT 'Silver conserves published municipal business counts by activity', count(*)
FROM (VALUES ('municipios'), ('GAU')) l(zone_level) CROSS JOIN dirce_source d
LEFT JOIN businesses_by_level b ON b.zone_level = l.zone_level AND b.activity = d.activity
WHERE b.total IS DISTINCT FROM d.total
UNION ALL
SELECT 'Silver business measures are unknown at district level', count(*)
FROM lake.main.silver_zone_metrics
WHERE zone_level = 'distritos' AND coalesce(businesses_total, businesses_industry, businesses_construction,
    businesses_trade_transport_hospitality, businesses_services) IS NOT NULL;

-- INE uses dots for thousands and a comma for decimals. Empty fields and
-- dots used as placeholders are unpublished values. Unexpected formats stop the load.
CREATE TEMP MACRO ine_number(raw_value) AS (
    CASE WHEN trim(raw_value) IN ('', '.', '..') OR raw_value IS NULL THEN NULL
         WHEN regexp_full_match(trim(raw_value), '[+-]?([0-9]+|[0-9]{1,3}(\.[0-9]{3})+)(,[0-9]+)?')
         THEN replace(replace(trim(raw_value), '.', ''), ',', '.')::DOUBLE
         ELSE error('Unexpected INE number: ' || raw_value) END
);

CREATE TEMP TABLE ine_section_indicators AS
WITH indicators(table_id, indicador, metric) AS (VALUES
    ('30832', 'Población', 'population'),
    ('30824', 'Renta neta media por persona', 'income'),
    ('30825', 'Fuente de ingreso: salario', 'wages'),
    ('30825', 'Fuente de ingreso: pensiones', 'pensions'),
    ('30825', 'Fuente de ingreso: prestaciones por desempleo', 'unemployment'),
    ('37677', 'Índice de Gini', 'gini'),
    ('30832', 'Edad media de la población', 'age'),
    ('30832', 'Porcentaje de población de 65 y más años', 'over_65')
)
SELECT left(Secciones, 10) AS section_id, metric, ine_number(Total) AS value
FROM lake.main.bronze_ine_adrh JOIN indicators USING (table_id, indicador)
WHERE Periodo = '2023' AND Secciones IS NOT NULL;

CREATE TEMP TABLE ine_section_values AS
SELECT section_id,
       max(value) FILTER (WHERE metric = 'population') AS population,
       max(value) FILTER (WHERE metric = 'income') AS income,
       max(value) FILTER (WHERE metric = 'wages') AS wages,
       max(value) FILTER (WHERE metric = 'pensions') AS pensions,
       max(value) FILTER (WHERE metric = 'unemployment') AS unemployment,
       max(value) FILTER (WHERE metric = 'gini') AS gini,
       max(value) FILTER (WHERE metric = 'age') AS age,
       max(value) FILTER (WHERE metric = 'over_65') AS over_65
FROM ine_section_indicators
GROUP BY section_id;

CREATE TEMP TABLE section_zones AS
WITH mapped_sections AS (
    SELECT * FROM lake.main.bronze_mitma_zone_mapping WHERE seccion_ine <> 'NA'
), district_fallback AS (
    SELECT distrito_ine, mode(distrito_mitma ORDER BY distrito_mitma) AS district_id
    FROM mapped_sections GROUP BY distrito_ine
), municipality_fallback AS (
    SELECT municipio_ine, mode(distrito_mitma ORDER BY distrito_mitma) AS district_id
    FROM mapped_sections GROUP BY municipio_ine
), matched AS (
    SELECT i.section_id,
           coalesce(exact.distrito_mitma, district.district_id, municipality.district_id,
                    CASE WHEN left(i.section_id, 5) = '48916' THEN '48036' END) AS district_id,
           CASE WHEN exact.distrito_mitma IS NOT NULL THEN 'exact'
                WHEN district.district_id IS NOT NULL THEN 'by_district'
                WHEN municipality.district_id IS NOT NULL THEN 'by_municipality'
                WHEN left(i.section_id, 5) = '48916' THEN 'manual' END AS match_type
    FROM ine_section_values i
    LEFT JOIN mapped_sections exact ON i.section_id = exact.seccion_ine
    LEFT JOIN district_fallback district ON left(i.section_id, 7) = district.distrito_ine
    LEFT JOIN municipality_fallback municipality ON left(i.section_id, 5) = municipality.municipio_ine
    WHERE i.population IS NOT NULL
), hierarchy AS (
    SELECT DISTINCT distrito_mitma, municipio_mitma, gau_mitma FROM mapped_sections
)
SELECT m.section_id, zone_level, zone_id, m.match_type
FROM matched m LEFT JOIN hierarchy h ON h.distrito_mitma = m.district_id
CROSS JOIN LATERAL (VALUES ('distritos', m.district_id), ('municipios', h.municipio_mitma), ('GAU', h.gau_mitma)) z(zone_level, zone_id);

WITH levels(zone_level) AS (VALUES ('distritos'), ('municipios'), ('GAU')),
zone_links AS (
    SELECT zone_level, zone_id, m.seccion_ine, left(m.municipio_ine, 2) AS province_code
    FROM lake.main.bronze_mitma_zone_mapping m
    CROSS JOIN LATERAL (VALUES ('distritos', m.distrito_mitma), ('municipios', m.municipio_mitma), ('GAU', m.gau_mitma)) z(zone_level, zone_id)
), geometry_keys AS (
    SELECT zone_level, ID, count(DISTINCT geometry_type) AS kinds
    FROM lake.main.bronze_mitma_zone_geometries
    GROUP BY zone_level, ID
)
SELECT 'MITMA zone names cover all three levels' AS check_name, count(*) AS issues
FROM levels ANTI JOIN lake.main.bronze_mitma_zone_names USING (zone_level)
UNION ALL
SELECT 'MITMA zone names are present and unique',
       count(*) - count(DISTINCT (zone_level, ID)) + count(*) FILTER (
           WHERE coalesce(trim(ID), '') = '' OR coalesce(trim(name), '') = ''
               OR zone_level NOT IN (SELECT zone_level FROM levels))
FROM lake.main.bronze_mitma_zone_names
UNION ALL
SELECT 'MITMA geometry keys and values are present and unique',
       count(*) - count(DISTINCT (zone_level, ID, geometry_type)) + count(*) FILTER (
           WHERE coalesce(trim(ID), '') = '' OR geom IS NULL OR geometry_type NOT IN ('polygon', 'centroid'))
FROM lake.main.bronze_mitma_zone_geometries
UNION ALL
SELECT 'MITMA catalogued zones have a polygon and a centroid', count(*)
FROM lake.main.bronze_mitma_zone_names n LEFT JOIN geometry_keys g USING (zone_level, ID)
WHERE g.kinds IS DISTINCT FROM 2
UNION ALL
SELECT 'MITMA mapping has valid and unique populated section IDs',
       count(*) FILTER (WHERE seccion_ine IS DISTINCT FROM 'NA')
       - count(DISTINCT seccion_ine) FILTER (WHERE seccion_ine <> 'NA')
       + count(*) FILTER (WHERE seccion_ine <> 'NA' AND (
           NOT regexp_full_match(seccion_ine, '[0-9]{10}')
           OR distrito_ine IS DISTINCT FROM left(seccion_ine, 7)
           OR municipio_ine IS DISTINCT FROM left(seccion_ine, 5)))
FROM lake.main.bronze_mitma_zone_mapping
UNION ALL
SELECT 'MITMA mapping covers named zones exactly at their respective levels', count(*)
FROM (SELECT DISTINCT zone_level, zone_id FROM zone_links) m
FULL JOIN lake.main.bronze_mitma_zone_names n ON m.zone_level = n.zone_level AND m.zone_id = n.ID
WHERE m.zone_id IS NULL OR n.ID IS NULL
UNION ALL
SELECT 'MITMA districts and municipalities each have one parent at the next levels', count(*)
FROM (
    SELECT distrito_mitma FROM lake.main.bronze_mitma_zone_mapping GROUP BY distrito_mitma
    HAVING count(DISTINCT (municipio_mitma, gau_mitma)) <> 1
    UNION ALL
    SELECT municipio_mitma FROM lake.main.bronze_mitma_zone_mapping GROUP BY municipio_mitma
    HAVING count(DISTINCT gau_mitma) <> 1
)
UNION ALL
SELECT 'MITMA populated zones each have one valid province', count(*)
FROM (
    SELECT zone_level, zone_id FROM zone_links z
    LEFT JOIN lake.main.bronze_ine_provinces p ON p.CPRO = z.province_code
    WHERE seccion_ine <> 'NA' GROUP BY zone_level, zone_id
    HAVING count(DISTINCT z.province_code) <> 1 OR count(*) FILTER (WHERE p.CPRO IS NULL) > 0
)
UNION ALL
SELECT 'INE province list covers 52 unique provinces and 19 communities/cities',
       abs(count(*) - 52) + abs(count(DISTINCT CPRO) - 52) + abs(count(DISTINCT CODAUTO) - 19)
       + count(*) FILTER (WHERE NOT regexp_full_match(CPRO, '[0-9]{2}') OR NOT regexp_full_match(CODAUTO, '[0-9]{2}')
           OR coalesce(trim(Provincia), '') = '' OR coalesce(trim("Comunidad Autónoma"), '') = '')
FROM lake.main.bronze_ine_provinces
UNION ALL
SELECT 'INE ADRH includes reference-year rows in each input table', count(*)
FROM (VALUES ('30832'), ('30824'), ('30825'), ('37677')) AS expected(table_id)
ANTI JOIN (SELECT DISTINCT table_id FROM lake.main.bronze_ine_adrh WHERE Periodo = '2023') USING (table_id)
UNION ALL
SELECT 'INE DIRCE includes the national reference-year total', abs(count(*) - 1)
FROM lake.main.bronze_ine_dirce
WHERE Periodo = '2023' AND Provincias IS NULL AND Municipios IS NULL AND "Grupos CNAE" = 'Total' AND Total IS NOT NULL
UNION ALL
SELECT 'BOE contains all 19 regions and unique holiday/region observations',
       abs(count(DISTINCT ccaa) - 19) + count(*) - count(DISTINCT (year, mes, fiesta, ccaa))
       + count(*) FILTER (WHERE marca NOT IN ('', '*', '**', '***') OR marca IS NULL)
FROM lake.main.bronze_boe_holidays;

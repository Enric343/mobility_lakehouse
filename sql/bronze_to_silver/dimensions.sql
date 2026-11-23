INSERT INTO lake.main.silver_dim_ccaa
SELECT DISTINCT CODAUTO, "Comunidad Autónoma" FROM lake.main.bronze_ine_provinces;

INSERT INTO lake.main.silver_dim_province
SELECT CPRO, Provincia, CODAUTO FROM lake.main.bronze_ine_provinces;

INSERT INTO lake.main.silver_dim_zone BY NAME
WITH zone_provinces AS (
    SELECT zone_level, zone_id, min(left(m.municipio_ine, 2)) AS province_code
    FROM lake.main.bronze_mitma_zone_mapping m
    CROSS JOIN LATERAL (VALUES ('distritos', m.distrito_mitma), ('municipios', m.municipio_mitma), ('GAU', m.gau_mitma)) z(zone_level, zone_id)
    WHERE m.seccion_ine <> 'NA'
    GROUP BY zone_level, zone_id
), geometries AS (
    SELECT zone_level, ID AS zone_id,
           any_value(geom) FILTER (WHERE geometry_type = 'polygon') AS geom,
           any_value(geom) FILTER (WHERE geometry_type = 'centroid') AS centroid
    FROM lake.main.bronze_mitma_zone_geometries
    GROUP BY zone_level, ID
), zone_keys AS (
    SELECT zone_level, zone_id FROM geometries
    UNION ALL SELECT * FROM (VALUES ('distritos', 'externo'), ('municipios', 'externo'), ('GAU', 'externo'))
)
SELECT z.zone_level, z.zone_id, coalesce(n.name, z.zone_id) AS zone_name, p.province_code,
       z.zone_id LIKE 'FR%' OR z.zone_id LIKE 'PT%' OR z.zone_id = 'externo' AS is_foreign,
       g.geom, g.centroid
FROM zone_keys z
LEFT JOIN lake.main.bronze_mitma_zone_names n ON z.zone_level = n.zone_level AND z.zone_id = n.ID
LEFT JOIN zone_provinces p ON z.zone_level = p.zone_level AND z.zone_id = p.zone_id
LEFT JOIN geometries g ON z.zone_level = g.zone_level AND z.zone_id = g.zone_id;

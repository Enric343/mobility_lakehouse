INSERT INTO lake.main.bronze_mitma_zone_geometries BY NAME
SELECT ID,
       CASE WHEN ST_CRS(geom) = 'EPSG:3042' THEN geom::GEOMETRY ELSE error('Expected MITMA CRS EPSG:3042') END AS geom,
       $kind AS geometry_type, $level AS zone_level,
       $source_file AS _source_file, current_timestamp AS _ingested_at
FROM ST_Read($path);

CREATE OR REPLACE TEMP TABLE gravity_candidates AS
WITH municipalities AS MATERIALIZED (
    SELECT z.zone_id, m.population, m.businesses_total,
           ST_Transform(z.centroid, 'EPSG:3042', 'EPSG:4326', true) AS lonlat
    FROM lake.main.silver_dim_zone z
    JOIN lake.main.silver_zone_metrics m USING (zone_level, zone_id)
    WHERE z.zone_level = 'municipios' AND NOT z.is_foreign AND z.centroid IS NOT NULL
), coordinates AS MATERIALIZED (
    SELECT zone_id, population, businesses_total,
           radians(ST_X(lonlat)) AS longitude, radians(ST_Y(lonlat)) AS latitude
    FROM municipalities
), distances AS (
    SELECT o.zone_id AS origin_zone_id, d.zone_id AS destination_zone_id,
           o.population AS origin_population, d.businesses_total AS destination_businesses,
           12742.0176 * asin(sqrt(least(1.0,
               sin((d.latitude - o.latitude) / 2)^2
               + cos(o.latitude) * cos(d.latitude) * sin((d.longitude - o.longitude) / 2)^2
           ))) AS distance_km
    FROM coordinates o CROSS JOIN coordinates d
    WHERE o.zone_id <> d.zone_id AND o.population > 0 AND d.businesses_total > 0
)
SELECT d.*, a.actual_trips, origin_population * destination_businesses / (distance_km^2) AS weight
FROM distances d
LEFT JOIN municipal_actual a USING (origin_zone_id, destination_zone_id)
WHERE distance_km > 0 AND isfinite(distance_km);

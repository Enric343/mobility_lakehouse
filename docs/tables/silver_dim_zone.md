# `silver_dim_zone`

Shared geography for mobility, metrics and maps.

| Property | Detail |
|---|---|
| Grain and key | One row per (`zone_level`, `zone_id`). |
| Inputs | [`bronze_mitma_zone_names`](bronze_mitma_zone_names.md), [`bronze_mitma_zone_geometries`](bronze_mitma_zone_geometries.md), [`bronze_mitma_zone_mapping`](bronze_mitma_zone_mapping.md) |
| Transformation | • Pair each zone's polygon and centroid by (`zone_level`, `zone_id`).<br>• Attach the name and derive `province_code` from the INE mapping.<br>• Flag foreign zones (`is_foreign`) and add an `externo` row per level.<br>[Dimension SQL](../../sql/bronze_to_silver/dimensions.sql) |
| Storage | Unpartitioned Parquet. Geometry coordinates are EPSG:3042. |
| Validation | Checks unique keys, geometry coverage where applicable and valid province links. [Silver reference checks](../../sql/validation/reference_silver.sql) |
| Used by | Silver fact joins, Gold pair distances and report boundaries. |

## Columns

One row per zone and level, including foreign zones (from the geometries) and a hand-added `externo` with no geometry.

| Column | Type | Description |
|---|---|---|
| `zone_level` | VARCHAR | `distritos`, `municipios`, `GAU` (PK) |
| `zone_id` | VARCHAR | Zone code (PK) |
| `zone_name` | VARCHAR | Name; for foreign zones, the code itself |
| `province_code` | VARCHAR | First 2 digits of `municipio_ine` in the mapping (not from the ID). `NULL` for foreign zones and the 49 unpopulated lands. FK → `silver_dim_province` |
| `is_foreign` | BOOLEAN | `true` for `FR*`, `PT*`, `externo` |
| `geom` | GEOMETRY | Polygon, EPSG:3042 |
| `centroid` | GEOMETRY | Centroid, EPSG:3042 |

The municipality and GAU of a district are not stored; derive them from `bronze_mitma_zone_mapping` only if residence must be aggregated above district level.

## Inspect the data

```sql
SELECT zone_id, zone_name, province_code, geom IS NOT NULL AS has_polygon
FROM lake.main.silver_dim_zone
WHERE zone_level = 'municipios' AND zone_id IN ('28079', 'externo');
```

[Table catalog](README.md) · [Silver column contract](../../sql/schema/silver.sql)

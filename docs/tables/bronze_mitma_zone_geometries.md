# `bronze_mitma_zone_geometries`

The spatial features of MITMA zones.

| Property | Detail |
|---|---|
| Grain and key | One feature per (`zone_level`, `ID`, `geometry_type`), either a polygon or a centroid. |
| Inputs | MITMA polygon and centroid shapefiles for each zoning level. |
| Transformation | • Store each feature as `GEOMETRY`, preserving EPSG:3042 coordinates.<br>• Add `geometry_type` (polygon/centroid), `zone_level` and lineage.<br>[Shapefile ingestion](../../sql/ingestion/mitma_geometry.sql) |
| Storage | Unpartitioned Parquet in DuckLake. |
| Validation | Checks CRS during ingestion and verifies the spatial keys and feature coverage. [Bronze reference checks](../../sql/validation/reference_bronze.sql) |
| Used by | [`silver_dim_zone`](silver_dim_zone.md) |

## Columns

Includes 117 French and Portuguese zones not present in the names files.

| Column | Type | Description |
|---|---|---|
| `ID` | VARCHAR | Zone code |
| `geom` | GEOMETRY | Polygon or centroid point, EPSG:3042 (metres) |
| `geometry_type` | VARCHAR | Added: `polygon` / `centroid` |
| `zone_level` | VARCHAR | Added: `distritos`, `municipios`, `GAU` |

Plus `_source_file VARCHAR` and `_ingested_at TIMESTAMPTZ` (lineage, on every Bronze table).

## Inspect the data

```sql
SELECT ID, geometry_type, _source_file
FROM lake.main.bronze_mitma_zone_geometries
WHERE zone_level = 'municipios' AND ID = '28079';
```

[Table catalog](README.md) · [Bronze DDL](../../sql/schema/bronze.sql)

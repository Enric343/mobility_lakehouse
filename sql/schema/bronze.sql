CREATE TABLE IF NOT EXISTS lake.main.bronze_mitma_od_daily (
    fecha VARCHAR, periodo VARCHAR, origen VARCHAR, destino VARCHAR, distancia VARCHAR,
    actividad_origen VARCHAR, actividad_destino VARCHAR,
    estudio_origen_posible VARCHAR, estudio_destino_posible VARCHAR,
    residencia VARCHAR, renta VARCHAR, edad VARCHAR, sexo VARCHAR, viajes VARCHAR, viajes_km VARCHAR,
    zone_level VARCHAR, _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.bronze_mitma_overnight_daily (
    fecha VARCHAR, zona_residencia VARCHAR, zona_pernoctacion VARCHAR, personas VARCHAR,
    zone_level VARCHAR, _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.bronze_mitma_zone_names (
    ID VARCHAR, name VARCHAR, zone_level VARCHAR, _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.bronze_mitma_zone_geometries (
    ID VARCHAR, geom GEOMETRY, geometry_type VARCHAR, zone_level VARCHAR,
    _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.bronze_mitma_zone_mapping (
    seccion_ine VARCHAR, distrito_ine VARCHAR, municipio_ine VARCHAR,
    distrito_mitma VARCHAR, municipio_mitma VARCHAR, gau_mitma VARCHAR,
    _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.bronze_ine_adrh (
    Municipios VARCHAR, Distritos VARCHAR, Secciones VARCHAR, indicador VARCHAR,
    Periodo VARCHAR, Total VARCHAR, table_id VARCHAR, _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.bronze_ine_dirce (
    "Totales Territoriales" VARCHAR, Provincias VARCHAR, Municipios VARCHAR, "Grupos CNAE" VARCHAR,
    Periodo VARCHAR, Total VARCHAR, _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.bronze_ine_provinces (
    CODAUTO VARCHAR, "Comunidad Autónoma" VARCHAR, CPRO VARCHAR, Provincia VARCHAR,
    _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.bronze_boe_holidays (
    year VARCHAR, mes VARCHAR, fiesta VARCHAR, ccaa VARCHAR, marca VARCHAR,
    _source_file VARCHAR, _ingested_at TIMESTAMPTZ
);

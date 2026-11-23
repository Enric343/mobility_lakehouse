-- Copy column names and types from the common Silver contract. DuckLake
-- integrity checks run as queries, since CTAS does not copy PK/FK constraints.
CREATE TABLE IF NOT EXISTS lake.main.silver_dim_ccaa AS FROM memory.silver_contract.silver_dim_ccaa LIMIT 0;
CREATE TABLE IF NOT EXISTS lake.main.silver_dim_province AS FROM memory.silver_contract.silver_dim_province LIMIT 0;
CREATE TABLE IF NOT EXISTS lake.main.silver_dim_zone AS FROM memory.silver_contract.silver_dim_zone LIMIT 0;
CREATE TABLE IF NOT EXISTS lake.main.silver_holidays AS FROM memory.silver_contract.silver_holidays LIMIT 0;
CREATE TABLE IF NOT EXISTS lake.main.silver_zone_metrics AS FROM memory.silver_contract.silver_zone_metrics LIMIT 0;
CREATE TABLE IF NOT EXISTS lake.main.silver_fact_trips AS FROM memory.silver_contract.silver_fact_trips LIMIT 0;
CREATE TABLE IF NOT EXISTS lake.main.silver_fact_overnight AS FROM memory.silver_contract.silver_fact_overnight LIMIT 0;

ALTER TABLE lake.main.bronze_mitma_od_daily SET PARTITIONED BY (zone_level, fecha);
ALTER TABLE lake.main.bronze_mitma_overnight_daily SET PARTITIONED BY (zone_level, fecha);
ALTER TABLE lake.main.bronze_ine_adrh SET PARTITIONED BY (table_id);
ALTER TABLE lake.main.silver_fact_trips SET PARTITIONED BY (
    zone_level, year(trip_datetime), month(trip_datetime), day(trip_datetime)
);
ALTER TABLE lake.main.silver_fact_overnight SET PARTITIONED BY (zone_level, date);

CREATE TABLE IF NOT EXISTS lake.main.reference_load (
    reference_year INTEGER, loaded_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lake.main.mobility_loads (
    dataset VARCHAR, zone_level VARCHAR, observation_date DATE, source_file VARCHAR,
    bronze_rows BIGINT, silver_rows BIGINT, published_total DOUBLE, loaded_at TIMESTAMPTZ
);

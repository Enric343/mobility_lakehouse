CREATE TABLE IF NOT EXISTS lake.main.gold_typical_day_patterns (
    period_start DATE, period_end DATE, zone_level VARCHAR, pattern_basis VARCHAR, day_type VARCHAR, hour_of_day BIGINT,
    origin_zone_id VARCHAR, destination_zone_id VARCHAR, avg_hourly_trips DOUBLE, observed_days BIGINT
);
CREATE TABLE IF NOT EXISTS lake.main.gold_day_assignments (
    period_start DATE, period_end DATE, zone_level VARCHAR, date DATE, day_type VARCHAR,
    cluster_id INTEGER, total_trips DOUBLE, peak_hour BIGINT
);
CREATE TABLE IF NOT EXISTS lake.main.gold_hourly_demand (
    period_start DATE, period_end DATE, zone_level VARCHAR, pattern_basis VARCHAR, pattern VARCHAR,
    hour_of_day BIGINT, avg_hourly_trips DOUBLE, observed_days BIGINT
);
CREATE TABLE IF NOT EXISTS lake.main.gold_origin_demand (
    period_start DATE, period_end DATE, zone_level VARCHAR, origin_zone_id VARCHAR, day_type VARCHAR,
    avg_daily_trips DOUBLE, observed_days BIGINT
);
CREATE TABLE IF NOT EXISTS lake.main.gold_infrastructure_gaps (
    period_start DATE, period_end DATE, zone_level VARCHAR, origin_zone_id VARCHAR, destination_zone_id VARCHAR,
    origin_population DOUBLE, destination_businesses INTEGER, distance_km DOUBLE, actual_trips DOUBLE,
    estimated_trips DOUBLE, actual_to_estimated_ratio DOUBLE
);
CREATE TABLE IF NOT EXISTS lake.main.gold_gravity_zone_ranking (
    period_start DATE, period_end DATE, zone_level VARCHAR, origin_zone_id VARCHAR, origin_population DOUBLE,
    eligible_pairs BIGINT, observed_pairs BIGINT, pair_coverage DOUBLE,
    actual_trips DOUBLE, estimated_on_observed_pairs DOUBLE, service_ratio DOUBLE, gap_rank BIGINT
);
CREATE TABLE IF NOT EXISTS lake.main.gold_gravity_calibration (
    period_start DATE, period_end DATE, zone_level VARCHAR, gravity_k DOUBLE,
    eligible_pairs BIGINT, observed_pairs BIGINT, observed_trips DOUBLE, estimated_on_observed_pairs DOUBLE
);
CREATE TABLE IF NOT EXISTS lake.main.gold_runs (
    period_start DATE, period_end DATE, model_revision VARCHAR, completed_at TIMESTAMPTZ
);

ALTER TABLE lake.main.gold_typical_day_patterns SET PARTITIONED BY (period_start, period_end, zone_level, pattern_basis);
ALTER TABLE lake.main.gold_infrastructure_gaps SET PARTITIONED BY (period_start, period_end);

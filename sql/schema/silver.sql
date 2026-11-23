CREATE TABLE silver_dim_ccaa (
    ccaa_code VARCHAR PRIMARY KEY,
    ccaa VARCHAR NOT NULL
);

CREATE TABLE silver_dim_province (
    province_code VARCHAR PRIMARY KEY,
    province_name VARCHAR NOT NULL,
    ccaa_code VARCHAR NOT NULL REFERENCES silver_dim_ccaa (ccaa_code)
);

CREATE TABLE silver_dim_zone (
    zone_level VARCHAR,
    zone_id VARCHAR,
    zone_name VARCHAR NOT NULL,
    province_code VARCHAR REFERENCES silver_dim_province (province_code),
    is_foreign BOOLEAN NOT NULL,
    geom GEOMETRY,
    centroid GEOMETRY,
    PRIMARY KEY (zone_level, zone_id)
);

CREATE TABLE silver_holidays (
    date DATE,
    ccaa_code VARCHAR REFERENCES silver_dim_ccaa (ccaa_code),
    holiday_name VARCHAR NOT NULL,
    PRIMARY KEY (date, ccaa_code)
);

CREATE TABLE silver_zone_metrics (
    zone_level VARCHAR,
    zone_id VARCHAR,
    population DOUBLE,
    mean_income_per_person DOUBLE,
    pct_income_wages DOUBLE,
    pct_income_pensions DOUBLE,
    pct_income_unemployment DOUBLE,
    gini DOUBLE,
    mean_age DOUBLE,
    pct_over_65 DOUBLE,
    businesses_total INTEGER,
    businesses_industry INTEGER,
    businesses_construction INTEGER,
    businesses_trade_transport_hospitality INTEGER,
    businesses_services INTEGER,
    PRIMARY KEY (zone_level, zone_id),
    FOREIGN KEY (zone_level, zone_id) REFERENCES silver_dim_zone (zone_level, zone_id)
);

CREATE TABLE silver_fact_trips (
    trip_datetime TIMESTAMP,
    zone_level VARCHAR,
    origin_zone_id VARCHAR,
    destination_zone_id VARCHAR,
    origin_activity VARCHAR,
    destination_activity VARCHAR,
    trips DOUBLE,
    PRIMARY KEY (trip_datetime, zone_level, origin_zone_id, destination_zone_id, origin_activity, destination_activity),
    FOREIGN KEY (zone_level, origin_zone_id) REFERENCES silver_dim_zone (zone_level, zone_id),
    FOREIGN KEY (zone_level, destination_zone_id) REFERENCES silver_dim_zone (zone_level, zone_id)
);

CREATE TABLE silver_fact_overnight (
    date DATE,
    zone_level VARCHAR,
    residence_district_id VARCHAR,
    overnight_zone_id VARCHAR,
    people DOUBLE,
    PRIMARY KEY (date, zone_level, residence_district_id, overnight_zone_id),
    FOREIGN KEY (zone_level, overnight_zone_id) REFERENCES silver_dim_zone (zone_level, zone_id)
);

CREATE OR REPLACE TEMP TABLE daily_profiles AS
SELECT zone_level, date, hour_of_day, sum(trips) AS trips
FROM daily_od GROUP BY zone_level, date, hour_of_day;

CREATE OR REPLACE TEMP TABLE daily_demand AS
WITH national_holidays AS (
    SELECT date FROM lake.main.silver_holidays GROUP BY date
    HAVING count(DISTINCT ccaa_code) = (SELECT count(*) FROM lake.main.silver_dim_ccaa)
)
SELECT zone_level, profiles.date, mobility_day_type(profiles.date, h.date IS NOT NULL) AS day_type,
       sum(trips) AS total_trips,
       first(hour_of_day ORDER BY trips DESC, hour_of_day) AS peak_hour
FROM daily_profiles profiles
LEFT JOIN national_holidays h USING (date)
GROUP BY zone_level, profiles.date, day_type;

CREATE TABLE gold_overnight_presence AS
WITH by_overnight_zone AS (
    SELECT date, overnight_zone_id AS district_id, SUM(people) AS people_present
    FROM silver_fact_overnight
    WHERE zone_level = 'distritos'
    GROUP BY date, district_id
), by_residence AS (
    SELECT date, residence_district_id AS district_id, SUM(people) AS people_by_residence
    FROM silver_fact_overnight
    WHERE zone_level = 'distritos'
    GROUP BY date, district_id
)
SELECT
    date,
    district_id,
    people_present,
    people_by_residence,
    people_present - people_by_residence AS net_overnight_people
FROM by_overnight_zone
FULL OUTER JOIN by_residence USING (date, district_id);

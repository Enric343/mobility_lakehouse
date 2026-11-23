CREATE OR REPLACE TEMP MACRO mobility_day_type(day, is_holiday) AS (
    CASE WHEN is_holiday THEN 'holiday'
         WHEN isodow(day) IN (6, 7) THEN 'weekend'
         ELSE 'weekday' END
);

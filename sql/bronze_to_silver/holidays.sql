INSERT INTO lake.main.silver_holidays BY NAME
WITH months(mes, month_number) AS (VALUES
    ('ENERO', 1), ('FEBRERO', 2), ('MARZO', 3), ('ABRIL', 4), ('MAYO', 5), ('JUNIO', 6),
    ('JULIO', 7), ('AGOSTO', 8), ('SEPTIEMBRE', 9), ('OCTUBRE', 10), ('NOVIEMBRE', 11), ('DICIEMBRE', 12)
), regions(boe_name, ccaa_code) AS (VALUES
    ('Andalucía', '01'), ('Aragón', '02'), ('Asturias', '03'), ('Illes Balears', '04'),
    ('Canarias', '05'), ('Cantabria', '06'), ('Castilla y León', '07'), ('Castilla-La Mancha', '08'),
    ('Cataluña', '09'), ('Comunitat Valenciana', '10'), ('Extremadura', '11'), ('Galicia', '12'),
    ('Com. Madrid', '13'), ('Región Murcia', '14'), ('C. Foral Navarra', '15'), ('País Vasco', '16'),
    ('La Rioja', '17'), ('Ciudad de Ceuta', '18'), ('Ciudad de Melilla', '19')
)
SELECT make_date(year::INT, month_number, regexp_extract(fiesta, '^[0-9]+')::INT) AS date,
       ccaa_code, trim(regexp_replace(fiesta, '^[0-9]+', '')) AS holiday_name
FROM lake.main.bronze_boe_holidays b
LEFT JOIN months USING (mes)
LEFT JOIN regions ON trim(regexp_replace(b.ccaa, '\([0-9]+\)', '')) = boe_name
WHERE marca <> '';

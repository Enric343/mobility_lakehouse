-- DIRCE is published by municipality. Los Montesinos (03903) stays in
-- its own MITMA municipality rather than splitting its published total.
CREATE TEMP TABLE business_municipality_map AS
SELECT DISTINCT municipio_ine, municipio_mitma, gau_mitma
FROM lake.main.bronze_mitma_zone_mapping
WHERE seccion_ine <> 'NA' AND NOT (municipio_ine = '03903' AND municipio_mitma = '03015');

CREATE TEMP TABLE dirce_municipal_values AS
SELECT left(Municipios, 5) AS municipality_ine, "Grupos CNAE" AS activity, ine_number(Total) AS businesses
FROM lake.main.bronze_ine_dirce
WHERE Periodo = '2023' AND Municipios IS NOT NULL AND "Grupos CNAE" IN (
    'Total', 'Industria', 'F Construcción', 'Comercio, transporte y hostelería', 'Total servicios');

CREATE TEMP MACRO weighted_mean(value, population) AS (
    sum(value * population) / nullif(sum(population) FILTER (WHERE value IS NOT NULL), 0)
);

INSERT INTO lake.main.silver_zone_metrics BY NAME
WITH residents AS (
    SELECT zone_level, zone_id, sum(population) AS population,
           weighted_mean(income, population) AS mean_income_per_person,
           weighted_mean(wages, population) AS pct_income_wages,
           weighted_mean(pensions, population) AS pct_income_pensions,
           weighted_mean(unemployment, population) AS pct_income_unemployment,
           weighted_mean(gini, population) AS gini,
           weighted_mean(age, population) AS mean_age,
           weighted_mean(over_65, population) AS pct_over_65
    FROM section_zones JOIN ine_section_values USING (section_id)
    GROUP BY zone_level, zone_id
), businesses AS (
    SELECT zone_level, zone_id,
           sum(businesses) FILTER (WHERE activity = 'Total')::INTEGER AS businesses_total,
           sum(businesses) FILTER (WHERE activity = 'Industria')::INTEGER AS businesses_industry,
           sum(businesses) FILTER (WHERE activity = 'F Construcción')::INTEGER AS businesses_construction,
           sum(businesses) FILTER (WHERE activity = 'Comercio, transporte y hostelería')::INTEGER AS businesses_trade_transport_hospitality,
           sum(businesses) FILTER (WHERE activity = 'Total servicios')::INTEGER AS businesses_services
    FROM dirce_municipal_values d JOIN business_municipality_map m ON m.municipio_ine = d.municipality_ine
    CROSS JOIN LATERAL (VALUES ('municipios', m.municipio_mitma), ('GAU', m.gau_mitma)) z(zone_level, zone_id)
    GROUP BY zone_level, zone_id
)
SELECT * FROM residents LEFT JOIN businesses USING (zone_level, zone_id);

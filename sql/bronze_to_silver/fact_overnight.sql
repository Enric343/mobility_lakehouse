SELECT strptime(fecha, '%Y%m%d')::DATE AS date, zone_level, zona_residencia AS residence_district_id,
       zona_pernoctacion AS overnight_zone_id, personas::DOUBLE AS people
FROM query_table($source_table);

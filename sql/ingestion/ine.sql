INSERT INTO lake.main.bronze_ine_adrh BY NAME
SELECT Municipios, Distritos, Secciones,
       coalesce("Indicadores demográficos", "Distribución por fuente de ingresos", "Indicadores de renta media") AS indicador,
       Periodo, Total, regexp_extract(parse_filename(filename), '_([0-9]+)\.csv$', 1) AS table_id,
       substring(filename, length(getvariable('raw_dir')) + 2) AS _source_file,
       current_timestamp AS _ingested_at
FROM read_csv(getvariable('adrh_paths'), delim=';', header=true, all_varchar=true, union_by_name=true, filename=true);

INSERT INTO lake.main.bronze_ine_dirce BY NAME
SELECT *, getvariable('dirce_source') AS _source_file, current_timestamp AS _ingested_at
FROM read_csv(getvariable('dirce_path'), delim=';', header=true, all_varchar=true);

INSERT INTO lake.main.bronze_ine_provinces BY NAME
SELECT *, getvariable('provincial_source') AS _source_file, current_timestamp AS _ingested_at
FROM read_csv(getvariable('provincial_path'), delim=';', header=true, all_varchar=true);

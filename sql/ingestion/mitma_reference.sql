INSERT INTO lake.main.bronze_mitma_zone_names BY NAME
SELECT ID, name, regexp_extract(filename, '/zonificacion_(distritos|municipios|GAU)/', 1) AS zone_level,
       substring(filename, length(getvariable('raw_dir')) + 2) AS _source_file,
       current_timestamp AS _ingested_at
FROM read_csv(getvariable('zone_names'), delim='|', header=true, all_varchar=true,
              union_by_name=true, filename=true);

INSERT INTO lake.main.bronze_mitma_zone_mapping BY NAME
SELECT *, getvariable('zone_mapping_source') AS _source_file, current_timestamp AS _ingested_at
FROM read_csv(getvariable('zone_mapping_path'), delim='|', header=true, all_varchar=true);

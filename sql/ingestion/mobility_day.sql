CREATE TEMP TABLE daily_bronze AS
SELECT *, $level AS zone_level, $source_file AS _source_file, current_timestamp AS _ingested_at
FROM read_csv($path, delim='|', header=true, all_varchar=true);

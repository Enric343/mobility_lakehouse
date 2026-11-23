CREATE OR REPLACE TEMP VIEW patterned_od AS
SELECT od.*, 'cluster' AS pattern_basis, 'cluster_' || d.cluster_id::VARCHAR AS day_type
FROM daily_od od JOIN daily_labels d USING (zone_level, date);

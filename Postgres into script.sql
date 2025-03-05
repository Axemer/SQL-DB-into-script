SELECT 
    'CREATE TABLE "' || table_schema || '"."' || table_name || '" (' || E'\n' ||
    STRING_AGG(
        '  "' || column_name || '" ' || 
        udt_name ||
        CASE 
            WHEN udt_name IN ('varchar', 'char') THEN '(' || character_maximum_length || ')'
            WHEN udt_name IN ('numeric') THEN '(' || numeric_precision || ',' || numeric_scale || ')'
            ELSE ''
        END ||
        CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END,
        ',' || E'\n'
        ORDER BY ordinal_position
    ) || E'\n);' AS SQLText
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_name NOT IN ('spt_fallback_db', 'spt_fallback_dev', 'spt_fallback_usg', 'spt_monitor', 'spt_values')
GROUP BY table_schema, table_name

UNION ALL

SELECT 
    'INSERT INTO "' || table_schema || '"."' || table_name || '" (' ||
    STRING_AGG('"' || column_name || '"', ', ' ORDER BY ordinal_position) ||
    ') SELECT ' ||
    STRING_AGG('"' || column_name || '"', ', ' ORDER BY ordinal_position) ||
    ' FROM "' || table_schema || '"."' || table_name || '";' AS SQLText
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_name NOT IN ('spt_fallback_db', 'spt_fallback_dev', 'spt_fallback_usg', 'spt_monitor', 'spt_values')
GROUP BY table_schema, table_name;

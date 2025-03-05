SET SESSION group_concat_max_len = 1000000;

SELECT CONCAT(
    'CREATE TABLE `', TABLE_SCHEMA, '`.`', TABLE_NAME, '` (\n',
    GROUP_CONCAT(
        CONCAT(
            '  `', COLUMN_NAME, '` ', 
            COLUMN_TYPE,
            IF(IS_NULLABLE = 'NO', ' NOT NULL', '')
        ) 
        ORDER BY ORDINAL_POSITION SEPARATOR ',\n'
    ),
    '\n);'
) AS SQLText
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME NOT IN ('spt_fallback_db', 'spt_fallback_dev', 'spt_fallback_usg', 'spt_monitor', 'spt_values')
GROUP BY TABLE_SCHEMA, TABLE_NAME

UNION ALL

SELECT CONCAT(
    'INSERT INTO `', TABLE_NAME, '` (', 
    GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`') ORDER BY ORDINAL_POSITION SEPARATOR ', '),
    ') SELECT ', 
    GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`') ORDER BY ORDINAL_POSITION SEPARATOR ', '),
    ' FROM `', TABLE_NAME, '`;'
) AS SQLText
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME NOT IN ('spt_fallback_db', 'spt_fallback_dev', 'spt_fallback_usg', 'spt_monitor', 'spt_values')
GROUP BY TABLE_SCHEMA, TABLE_NAME;

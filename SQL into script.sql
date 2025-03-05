SET NOCOUNT ON;
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @TableName NVARCHAR(255);
DECLARE @Columns NVARCHAR(MAX);
DECLARE @InsertSQL NVARCHAR(MAX);

-- Making temp table for output SQL
DECLARE @Results TABLE (SQLText NVARCHAR(MAX));

-- =====================================
--  Generating CREATE TABLE (DDL)
-- =====================================
INSERT INTO @Results (SQLText)
SELECT 'CREATE TABLE ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ' (' +
       STRING_AGG(QUOTENAME(COLUMN_NAME) + ' ' + DATA_TYPE +
                  CASE 
                    WHEN DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar') 
                         THEN '(' + COALESCE(CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR), 'MAX') + ')'
                    WHEN DATA_TYPE IN ('decimal', 'numeric') 
                         THEN '(' + COALESCE(CAST(NUMERIC_PRECISION AS VARCHAR), '18') + ',' + COALESCE(CAST(NUMERIC_SCALE AS VARCHAR), '0') + ')'
                    ELSE ''
                  END +
                  CASE WHEN IS_NULLABLE = 'NO' THEN ' NOT NULL' ELSE '' END, ', ') 
       + ');'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME NOT IN ('spt_fallback_db', 'spt_fallback_dev', 'spt_fallback_usg', 'spt_monitor', 'spt_values', 'MSreplication_options')
GROUP BY TABLE_SCHEMA, TABLE_NAME;

-- =====================================
--  Generating INSERT INTO (DML)
-- =====================================
DECLARE TableCursor CURSOR FOR 
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
AND TABLE_NAME NOT IN ('spt_fallback_db', 'spt_fallback_dev', 'spt_fallback_usg', 'spt_monitor', 'spt_values', 'MSreplication_options');

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Getting column list
    SET @Columns = '';
    SELECT @Columns = COALESCE(@Columns + ', ', '') + QUOTENAME(COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = @TableName
    ORDER BY ORDINAL_POSITION;

    -- Generating SQL Inserts
    SET @InsertSQL = 'INSERT INTO ' + QUOTENAME(@TableName) + ' (' + @Columns + ') SELECT ' + @Columns + ' FROM ' + QUOTENAME(@TableName) + ';';

    INSERT INTO @Results (SQLText) VALUES (@InsertSQL);

    FETCH NEXT FROM TableCursor INTO @TableName;
END;

CLOSE TableCursor;
DEALLOCATE TableCursor;

-- =====================================
--  Output SQL-script
-- =====================================
SELECT SQLText FROM @Results;

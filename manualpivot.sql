USE db

-- Truncate the table to remove all existing data
TRUNCATE TABLE analytics_table.Nameplate_Aux_Monthly_Summary

-- Drop the temporary table if it exists
IF OBJECT_ID('tempdb..#Model_Type') IS NOT NULL
    DROP TABLE #Model_Type

-- Create a temporary table with trimmed and replaced values from the source table
SELECT
    TRIM(SUBSTRING(Field1, 0, CHARINDEX(' ', Field1, 0))) AS Model,
    REPLACE(Field1, TRIM(SUBSTRING(Field1, 0, CHARINDEX(' ', Field1, 0))), '') AS Type,
    *
INTO #Model_Type
FROM analytics_table.Sales_File_New
WHERE Field1 IS NOT NULL

-- Declare variables for cursor
DECLARE @Month VARCHAR(100), @Model VARCHAR(100), @Type VARCHAR(100), @SQL VARCHAR(MAX), @Month_Current VARCHAR(100), @Model_Current VARCHAR(100)

-- Declare cursor to iterate over records
DECLARE curInsertMain CURSOR FOR 
    SELECT * FROM analytics_table.Nameplate_Aux_Monthly_Model
OPEN curInsertMain

FETCH NEXT FROM curInsertMain INTO @Month, @Model

WHILE @@FETCH_STATUS <> -1
BEGIN
    -- Build dynamic SQL for inserting data into the summary table
    SET @SQL = '
    INSERT INTO analytics_table.Nameplate_Aux_Monthly_Summary
    SELECT TOP 1
        ''' + @Month + ''' AS Month,
        ISNULL((SELECT TOP 1 [' + @Month + '] FROM #Model_Type WHERE TRIM(Model) = ''' + @Model + ''' AND TRIM(Type) = ''Total''), 0) AS [Total Sales (VD+TD)],
        ISNULL((SELECT TOP 1 [' + @Month + '] FROM #Model_Type WHERE TRIM(Model) = ''' + @Model + ''' AND TRIM(Type) = ''VD''), 0) AS [Direct Sales],
        ISNULL((SELECT TOP 1 [' + @Month + '] FROM #Model_Type WHERE TRIM(Model) = ''' + @Model + ''' AND TRIM(Type) = ''Retail''), 0) AS [Retail Sales],
        ISNULL((SELECT TOP 1 [' + @Month + '] FROM #Model_Type WHERE TRIM(Model) = ''' + @Model + ''' AND TRIM(Type) = ''PDA''), 0) AS [PDA],
        ''BRASIL'' AS Market,
        UPPER('''+ @Model + ''') AS Nameplate,
        '''' AS FileName,
        GETDATE() AS LoadDate,
        NEWID() AS LineID
    FROM analytics_table.Sales_File_New
    WHERE Field1 IS NOT NULL
    AND Field1 LIKE ''%'' + ''' + @Model + ''' + ''%''
    '

    -- Execute the dynamic SQL
    EXECUTE (@SQL)

    -- Fetch the next record from the cursor
    FETCH NEXT FROM curInsertMain INTO @Month, @Model
END

-- Close and deallocate the cursor
CLOSE curInsertMain
DEALLOCATE curInsertMain

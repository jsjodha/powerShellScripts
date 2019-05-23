
SELECT tbl.DataBase_Name, tbl.Schema_Name, tbl.Table_Name , tbl.RowsCount, tbl.Key_Columns , tbl.DataSize 
, 'select '+CASE WHEN isnull(tbl.Key_Columns,'')='' THEN '0' ELSE replace(tbl.Key_Columns ,'||',',') end +' AS keys, CAST(hashbytes(''MD5'',(SELECT t.* FROM (VALUES(NULL))foo(bar)FOR xml auto)) AS bigint) AS [Hash]  FROM '+tbl.DataBase_Name+'.'+tbl.Schema_Name+'.'+tbl.Table_Name+' t ;' as Query
FROM (
SELECT DB_NAME() AS DataBase_Name, s.Name AS Schema_Name, t.Name AS Table_Name, t.object_id ,p.rows  AS RowsCount ,
	   Cast(cast(round((sum(a.total_pages) *8)/1024.0 ,2) as numeric(18,2)) as varchar(50))+'mb' as DataSize,
       Key_Columns = STUFF((
						SELECT '+''__''+ CAST('+ c.Name +' as varchar(50))'
						FROM sys.indexes AS i
							 INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
							 INNER JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
						WHERE i.is_primary_key = 1 AND i.object_id = t.object_id ORDER BY c.name FOR XML PATH('')
					), 1, 6, '') 
FROM sys.tables AS t	
     INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name NOT LIKE 'DT%'
AND t.is_ms_shipped = 0 AND i.object_id >255
GROUP BY s.name, t.name, p.rows, t.object_id 
) tbl
ORDER BY tbl.RowsCount DESC 





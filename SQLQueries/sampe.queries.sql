DECLARE @str varchaR(max) =(SELECT STRING_AGG(Column_Name,',')  FROM INFORMATION_SCHEMA.COLUMNS WHERE table_Name ='DBConnections'
and data_Type not in ('varbinary'))

DECLARE @query varchar(max) ='select  CAST(t.Pk_Id as varchar(50)) AS keys, 
CAST(hashbytes(''MD5'',(SELECT '+@str+' AS columnsNames 
 FROM (VALUES(NULL))foo(bar)FOR xml auto)) 
AS bigint) AS [Hash]  
FROM iCareMVCMaster.dbo.DBConnections t ;'

exec sp_executesql @str 

SELECT STRING_AGG(Column_Name,',')  FROM INFORMATION_SCHEMA.COLUMNS WHERE table_Name ='sysdiagrams'
and data_Type not in ('varbinary')














CREATE TABLE dbo.HashKeyById(Id int IDENTITY(1,1)

SELECT * INTO dbo.HashKeyOrdered FROM dbo.HashKeyTest ORDER BY dbo.HashKeyTest.id

DROP TABLE hashkeymap
CREATE TABLE dbo.HashKeyMap (id int PRIMARY key, HashValue bigint)

INSERT INTO dbo.HashKeyMap
SELECT IdentityKey , hashkey FROM dbo.HashKeyOrdered hkt


CREATE TABLE New_ICareMVCMaster.dbo.HashKeyMap (id int PRIMARY key, HashValue bigint)
Insert into New_ICareMVCMaster.dbo.HashKeyMap 
select * FROM dbo.HashKeyMap hkt

SELECT * FROM dbo.HashKeyMap s FULL OUTER JOIN New_ICareMVCMaster.dbo.HashKeyMap t
ON s.id = t.id
where 
s.id  <1000
and s.HashValue <> t.HashValue 


select  CAST(id as varchar(50)) AS keys, CAST(hashbytes('MD5',(SELECT t.* FROM (VALUES(NULL))foo(bar)FOR xml auto)) AS bigint) AS [Hash]  FROM dbo.HashKeyMap t

select  CAST(id as varchar(50)) AS keys, CAST(hashbytes('MD5',(SELECT t.* FROM (VALUES(NULL))foo(bar)FOR xml auto)) AS bigint) AS [Hash]  FROM New_ICareMVCMaster. dbo.HashKeyMap t

SELECT TOP 10  *FROM 
dbo.HashKeyMap s FULL OUTER JOIN New_ICareMVCMaster.dbo.HashKeyMap t 
ON t.id = s.id
WHERE t.HashValue != s.HashValue

SELECT TOP 100 * FROM ICareMVCMaster. dbo.HashKeyMap WHERE HashValue='4706135240658891687'
SELECT TOP 100 * FROM New_ICareMVCMaster.dbo. HashKeyMap WHERE HashValue ='4706135240658891697'





Find Wait states 

SELECT
    *
   ,wait_time_ms/waiting_tasks_count AS 'Avg Wait in ms'
FROM
   sys.dm_os_wait_stats 
WHERE
   waiting_tasks_count > 0
ORDER BY
   wait_time_ms DESC




query for keys and query finder.

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
--WHERE tbl.Key_Columns IS not NULL 
ORDER BY tbl.RowsCount DESC 









SELECT tbl.DataBase_Name, tbl.Schema_Name, tbl.Table_Name , tbl.RowsCount, tbl.Key_Columns , tbl.DataSize
, 'select '+CASE WHEN isnull(tbl.Key_Columns,'')='' THEN '0' ELSE replace(tbl.Key_Columns ,'||',',') end +' AS keys, CAST(hashbytes(''MD5'',(SELECT t.* FROM (VALUES(NULL))foo(bar)FOR xml auto)) AS bigint) AS [Hash]  FROM 'tbl.Schema_Name+'.'+tbl.Table_Name+' t ;' as Query
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
where tbl.Key_Columns is not null
ORDER BY tbl.RowsCount DESC



select  CAST(id as varchar(50)) AS keys, CAST(hashbytes('MD5',(SELECT t.* FROM (VALUES(NULL))foo(bar)FOR xml auto)) AS bigint) AS [Hash]  FROM dbo.HashKeyMap t
;

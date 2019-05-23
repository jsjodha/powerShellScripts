USE ICareMVCMaster
-- DROP TABLE dbo.HashKeyTest
CREATE TABLE HashKeyTest (id  uniqueidentifier, hashkey bigint)


 INSERT INTO dbo.HashKeyTest
SELECT *	 FROM (
SELECT MBT.keyId,
   hashbytes('MD5',
               (SELECT MBT.*
                FROM (
                      VALUES(NULL))foo(bar)
                FOR xml auto)) AS [Hash]
FROM ( SELECT newid() AS keyId, * FROM sys.all_objects ) AS MBT )a
 
GO 10000


SELECT hashkey, count(*) FROM dbo.HashKeyTest 
GROUP BY hashkey
HAVING count(*) >1
--TRUNCATE table dbo.HashKeyTest 



INSERT INTO iCareMVCMaster. dbo.HashKeyTest
(
    id,
    hashkey
)
SELECT * FROM New_ICareMVCMaster.dbo.HashKeyTest 
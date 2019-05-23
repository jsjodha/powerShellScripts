function Execute-Query {
    # Parameter help description
    [CmdletBinding()]
    Param
    ( 
        
        [Parameter(ValueFromPipeline=$True,Mandatory=$False)] 
        [string] $SqlServer="JSHOME",
        [Parameter(ValueFromPipeline=$True,Mandatory=$False)] 
        [string] $Database = "ICareMVCMaster",
        
        [Parameter(ValueFromPipeline=$True,Mandatory=$False)] 
        [string] $SqlStatement ="Select * from HashKeyTest",
        #[ValidateNotNullOrEmpty()] 
        [Parameter(ValueFromPipeline=$True,Mandatory=$False)] 
        [string] $OutFileName ="C:\temp\ExecuteReader_HeshKeyTest.csv"
    )
    #$ErrorActionPreference = "Stop"
    $VerbosePreference ="Verbose"

    $conSring="Data Source=$SqlServer;Initial Catalog=$Database;Integrated Security=true;"
    Write-Host  $conSring
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $conSring
    #$sqlConnection.ConnectionString = "Server=$SqlServer;Database=$Database;Integrated Security=True"
    $sqlConnection.Open()
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandText = $SqlStatement
    $sqlCmd.Connection = $sqlConnection
    
    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $sqlAdapter.SelectCommand = $sqlCmd
    Write-Host 'will write output to ' $OutFileName
    
    $file = New-Object System.IO.StreamWriter -ArgumentList ([IO.File]::Open($OutFileName,"Open"));
    $file.BaseStream.SetLength(0)
    $file.Write("This is a test!")
    try{ 
        $reader =  $sqlCmd.ExecuteReader()
        $recordsCount  =0;
        while ($reader.Read()) {
        $record =  $reader["ID"].ToString() +','+ $reader["HashKey"].ToString() 
        $file.Writeline($record);
        $recordsCount +=1;

         #Write-Host  $recordsCount  + "Reading  >"  $record
        }
        Write-Host $recordsCount 'Records Saved to ' $outfilePath

    }
    finally{
        # Clean up
        $file.Dispose()
        $sqlCmd.Dispose()
        $sqlConnection.Dispose()
    }
}
function Get-DataTable{
    # Parameter help description
    [CmdletBinding()]
    Param
    (         
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)] 
        [string] $SqlServer="JSHOME",
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)] 
        [string] $Database = "ICareMVCMaster",        
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)] 
        [string] $QueryText ="Select * from HashKeyTest"        
    )

    try{ 
        # Configure connection string
        $con = New-Object System.Data.SqlClient.SqlConnection("Data Source=$SqlServer;Integrated Security=true;Initial Catalog=$Database");
        # Create two sql statements for the tables
        Write-Host 'QueryText :' $QueryText
        # Create dataset objects
        $resultset1 = New-Object System.Data.DataSet "ds1";
        # Run query 1 and fill resultset1
        $data_adap = new-object System.Data.SqlClient.SqlDataAdapter ($QueryText, $con);        
        $data_adap.Fill($resultset1) | Out-Null;
        # Get data table (only first table will be compared).
        [System.Data.DataTable]$table = $resultset1.Tables[0];
        return $table    
    }
    finally{
        # Clean up
        $data_adap.Dispose();
        $con.Close();
        $con.Dispose();
    }
}



#Execute-Query  

$TableRowsCountAndKeysColumnsQuery  =@"

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

"@

$TableEntries = Get-DataTable -SqlServer 'JSHOME' -Database "ICareMVCMaster" -QueryText $TableRowsCountAndKeysColumnsQuery

#$TableEntries |Format-Table * 
# for ($i = 0; $i -lt $TableEntries.Rows.Count; $i++) {
#     $item =""
#     [System.Data.DataRow]$dr = $TableEntries.Rows[$i]
#     Write-host $dr
#     for($c =0; $c -lt $dr.ItemArray.Count; $c++) {       
#         $items += "|" + $dr[$i][$c]
#     } 
#     write-host  $item
# }
 $indexNum =0;
$obj = $TableEntries | ForEach-Object {
  
    $keys = [System.String] $_.Key_Columns
    $indexNum +=1;
    if(-not $keys ){        
        $keys =$indexNum
    }
    New-Object -TypeName PSObject -Property @{
      "DataBase_Name"   = [System.String] $_.DataBase_Name
      "Schema_Name"     = [System.String] $_.Schema_Name
      "Table_Name"      = [System.String] $_.Table_Name
      "RowsCount"       = [System.String] $_.RowsCount
      "Keys_Columns"    = [System.String] $_.Key_Columns
      "Query"           = [System.String] $_.Query
    }}

    Write-host 'Custom PS object '
    $obj |Format-Table *


$HashKeyQueryForTable = @"
SELECT t.$KeyColumns,hashbytes('MD5',(SELECT t.*FROM ( VALUES(NULL))foo(bar)FOR xml auto)) AS [Hash] FROM $dbName.$schemaname.$TableName AS t;
"@


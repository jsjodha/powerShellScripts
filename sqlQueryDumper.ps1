
# Param
# (           
#     [Parameter(ValueFromPipeline = $True, Mandatory = $False)] 
#     [string] $Source_SqlServer = "JSHOME",
#     [Parameter(ValueFromPipeline = $True, Mandatory = $False)] 
#     [string] $Target_SqlServer = "JSHOME",
#     [Parameter(ValueFromPipeline = $True, Mandatory = $False)]     
#     [string] $Source_Database = "ICareMVCMaster",
#     [Parameter(ValueFromPipeline = $True, Mandatory = $False)]     
#     [string] $Target_Database = "New_ICareMVCMaster"
# )

$Source_SqlServer = 'JSHOME'
$Target_SqlServer = 'JSHome'
$Source_DbName = 'ICareMVCMaster'
$Target_DbName = 'New_ICareMVCMaster'

function ExecuteQuery {
    ##Parameter help description
    [CmdletBinding()]
    Param
    (         
        [Parameter(Mandatory = $False)] 
        [string] $SqlServer,
        [Parameter(Mandatory = $False)] 
        [string] $Database ,        
        [Parameter(Mandatory = $False)] 
        [string] $SqlStatement ,
        #[ValidateNotNullOrEmpty()] 
        [Parameter(Mandatory = $False)] 
        [string] $OutputFileName 
    )

    $ParameterList = (Get-Command -Name $MyInvocation.InvocationName).Parameters;
    foreach ($key in $ParameterList.keys)
    {
        $var = Get-Variable -Name $key -ErrorAction SilentlyContinue;
        if($var)
        {
            write-host "$($var.name) > $($var.value)"

            if(-not $var.value){
                return " input value is missing for "+ $var.name +" value received as ["+ $var.value +"]"
                Exit ;
            }
        }
    }


    #$ErrorActionPreference = "Stop"
    #$VerbosePreference = "Verbose"

    $conSring = "Data Source=$SqlServer;Initial Catalog=$Database;Integrated Security=true;"
    Write-Host  "ConString :$conSring"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $conSring
    #$sqlConnection.ConnectionString = "Server=$SqlServer;Database=$Database;Integrated Security=True"
    $sqlConnection.Open()
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandText = $SqlStatement
    $sqlCmd.Connection = $sqlConnection
    
    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $sqlAdapter.SelectCommand = $sqlCmd
    
    Write-Host "SqlCommand: $SqlStatement"
    

    Write-Host 'will write output to ' $OutputFileName
    $file = New-Object System.IO.StreamWriter -ArgumentList ([IO.File]::Open($OutputFileName, "OpenOrCreate"));
    $file.BaseStream.SetLength(0)
    $file.Write("KEYS, HASH")
    try { 
        $reader = $sqlCmd.ExecuteReader()
        $recordsCount = 0;
        while ($reader.Read()) {
            $record = $reader["Keys"].ToString() + ',' + $reader["Hash"].ToString() 
            $file.Writeline($record);
            $recordsCount += 1;

            #Write-Host  $recordsCount  + "Reading  >"  $record
        }
        Write-Host $recordsCount 'Records Saved to ' $OutputFileName

    }
    catch{
       Write-Error "Error in ExecuteQuery:"+$_
    }
    finally {
        # Clean up
        $file.Dispose()
        $sqlCmd.Dispose()
        $sqlConnection.Dispose()
    }
}
function Get-DataTable {
    # Parameter help description
    [CmdletBinding()]
    Param
    (         
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)] 
        [string] $SqlServer,
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)] 
        [string] $Database ,        
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)] 
        [string] $QueryText  
    )

    try { 
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
    finally {
        # Clean up
        $data_adap.Dispose();
        $con.Close();
        $con.Dispose();
    }
}



#Execute-Query  

$TableRowsCountAndKeysColumnsQuery = @"

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
$indexNum = 0;
$TablesToMatch = $TableEntries | ForEach-Object {
  
    $keys = [System.String] $_.Key_Columns
    
    if (-not $keys ) {        
        $indexNum += 1;
        $keys = $indexNum
    }
    New-Object -TypeName PSObject -Property @{
        "DataBaseName" = [System.String] $_.DataBase_Name
        "SchemaName"   = [System.String] $_.Schema_Name
        "TableName"    = [System.String] $_.Table_Name
        "RowsCount"    = [System.String] $_.RowsCount
        "KeysColumns"  = [System.String] $_.Key_Columns
        "Query"        = [System.String] $_.Query
    } }

Write-host 'TablesToMatch output '
$TablesToMatch | Format-Table *


# foreach ($r in $TablesToMatch) {     
#     $queryText = '"' + $r.Query + '"'
#     $tableName = '"' + $r.TableName + '"'
#     Write-Host $queryText
#     Write-Host $tableName
#     Write-Host $r.GetType()

#     ExecuteQuery  -SqlServer $Source_SqlServer `
#         -Database $Source_DbName `
#         -SqlStatement $queryText `
#         -OutFileName 'E:\Temp\Source_'+$r.TableName;

#     ExecuteQuery  -SqlServer $Target_SqlServer  `
#         -Database $Target_DbName `
#         -SqlStatement $queryText `
#         -OutFileName 'E:\Temp\Target_'+$r.TableName;
# }

Function Compare-ObjectProperties {
    Param(
        [PSObject]$ReferenceObject,
        [PSObject]$DifferenceObject 
    )
    $objprops = $ReferenceObject | Get-Member -MemberType Property,NoteProperty | % Name
    $objprops += $DifferenceObject | Get-Member -MemberType Property,NoteProperty | % Name
    $objprops = $objprops | Sort | Select -Unique
    $diffs = @()
    foreach ($objprop in $objprops) {
        $diff = Compare-Object $ReferenceObject $DifferenceObject -Property $objprop
        if ($diff) {            
            $diffprops = @{
                PropertyName=$objprop
                RefValue=($diff | ? {$_.SideIndicator -eq '<='} | % $($objprop))
                DiffValue=($diff | ? {$_.SideIndicator -eq '=>'} | % $($objprop))
            }
            $diffs += New-Object PSObject -Property $diffprops
        }        
    }
    if ($diffs) {return ($diffs | Select PropertyName,RefValue,DiffValue)}     
}


foreach ($r in $TablesToMatch) {        
    $qry = $r.Query
    $tableName = $r.TableName
    $sourceOutFilename = "E:\Temp\$tableName.src"
 
     
        ExecuteQuery  -SqlServer $Source_SqlServer `
            -Database $Source_DbName `
            -SqlStatement $qry `
            -OutputFileName $sourceOutFilename;

        $targetOutFilename = "E:\Temp\$tableName.trg"

        ExecuteQuery  -SqlServer $Target_SqlServer  `
            -Database $Target_DbName `
            -SqlStatement $qry `
            -OutputFileName $targetOutFilename;
    
}


##Compare objects 
#Compare-Object -ReferenceObject $(Get-Content E:\Temp\HashKeyTest.src) -DifferenceObject $(Get-Content E:\temp\HashKeyTest.trg)
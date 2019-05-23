$PathVariables=$env:Path
$PathVariables
 
 
IF (-not $PathVariables.Contains( "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin"))
{
write-host "SQLPackage.exe path is not found, Update the environment variable"
$env:Path = $env:Path + ";C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin;" 
}

#extract all your database schemas as dacpacs
$server = 'DESKTOP-2BJ7HJE'

$dbs = Invoke-Sqlcmd -ServerInstance $server -Database tempdb -Query 'SELECT name FROM sys.databases WHERE database_id >4'

foreach($db in $dbs.name){
    $cmd = "& 'C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\sqlpackage.exe' /action:Extract /targetfile:'C:\temp\$db.dacpac' /SourceServerName:$server /SourceDatabaseName:$db"

    Invoke-Expression $cmd

}

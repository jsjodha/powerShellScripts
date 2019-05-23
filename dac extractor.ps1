function Export-SQLDacPacs {
    param([string[]] $Instances = '.',
        [string] $outputdirectory = "E:\Temp"
    )

    #get the sqlpackage executable
    #$sqlpackage = (get-childitem 'C:\Program Files\Microsoft SQL Server' -Recurse | Where-Object { $_.name -eq 'sqlpackage.exe' } | Sort-Object LastWriteTime | Select-Object -First 1).FullName
    $sqlpackage =  'C:\Program Files\Microsoft SQL Server\140\dac\bin\SqlPackage.exe'
    #declare a select query for databases
    $dbsql = @"
SELECT name FROM sys.databases
where database_id >4 and state_desc = 'ONLINE'
"@

    #loop through each instance
    foreach ($instance in $Instances) {
        #set processing variables
        $dbs = Invoke-Sqlcmd -ServerInstance $instance -Database tempdb -Query $dbsql
        $datestring = (Get-Date -Format 'yyyyMMddHHmm')
        $iname = $instance.Replace('\', '_')

        #extract each db
        foreach ($db in $dbs.name) {
            $outfile = Join-Path $outputdirectory -ChildPath "$iname-$db-$datestring.dacpac"
            $cmd = "& '$sqlpackage' /action:Extract /targetfile:'$outfile' /SourceServerName:$instance /SourceDatabaseName:$db"
            Invoke-Expression $cmd
        }
    }
}

Export-SQLDacPacs -instances '.' 
# add path for SQLPackage.exe
IF (-not ($env:Path).Contains( "C:\program files\microsoft sql server\130\DAC\bin"))
{ $env:path = $env:path + ";C:\program files\microsoft sql server\130\DAC\bin;" }

sqlpackage /a:extract /of:true /scs:"server=.\sql2016;database=db_source;trusted_connection=true" /tf:"C:\test\db_source.dacpac";

sqlpackage.exe /a:deployreport /op:"c:\test\report.xml" /of:True /sf:"C:\test\db_source.dacpac" /tcs:"server=.\sql2016; database=db_target;trusted_connection=True" 

[xml]$x = gc -Path "c:\test\report.xml";
$x.DeploymentReport.Operations.Operation |
% -Begin {$a=@();} -process {$name = $_.name; $_.Item | %  {$r = New-Object PSObject -Property @{Operation=$name; Value = $_.Value; Type = $_.Type} ; $a += $r;} }  -End {$a}


sqlpackage.exe /a:script /op:"c:\test\change.sql" /of:True /sf:"C:\test\db_source.dacpac" /tcs:"server=.\sql2016; database=db_target;trusted_connection=True"

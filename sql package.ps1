# add path for SQLPackage.exe
IF (-not ($env:Path).Contains( "C:\program files\microsoft sql server\140\DAC\bin"))
{ $env:path = $env:path + ";C:\program files\microsoft sql server\140\DAC\bin;" }

sqlpackage /a:extract /of:true /scs:"server=DESKTOP-2BJ7HJE;database=New_ICareMVCMaster;trusted_connection=true" /tf:"C:\temp\ICareMVCMaster_source.dacpac";

sqlpackage.exe /a:deployreport /op:"c:\temp\report.xml" /of:True /sf:"C:\temp\ICareMVCMaster_source.dacpac" /tcs:"server=DESKTOP-2BJ7HJE; database=ICareMVCMaster;trusted_connection=True" 


#generate script for changes in change.sql.
sqlpackage.exe /a:script /op:"c:\temp\change.sql" /of:True /sf:"C:\temp\IcareMVCMaster_source.dacpac" /tcs:"server=DESKTOP-2BJ7HJE; database=ICareMVCMaster;trusted_connection=True" /P:DropObjectsNotInSource=True


[xml]$x = gc -Path "c:\temp\report.xml";
$x.DeploymentReport.Operations.Operation |
% -Begin {$a=@();} -process {$name = $_.name; $_.Item | %  {$r = New-Object PSObject -Property @{Operation=$name; Value = $_.Value; Type = $_.Type} ; $a += $r;} }  -End {$a}

# load in DAC DLL (requires config file to support .NET 4.0)
# change file location for a 32-bit OS
add-type -path "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\Microsoft.SqlServer.Dac.dll"

# make DacServices object, needs a connection string
$d = new-object Microsoft.SqlServer.Dac.DacServices "server=DESKTOP-2BJ7HJE;Integrated Security = True;"

# register events, if you want 'em
register-objectevent -in $d -eventname Message -source "msg" -action { out-host -in $Event.SourceArgs[1].Message.Message }

# Extract DACPAC from database
# Extract pubs database to a file using DAC application name pubs, version 1.2.3.4
$version = New-Object Version("1.1.1.1")
$d.extract("c:\temp\ICareMVCMaster.dacpac", "ICareMVCMaster", "ICareMVCMaster", $version)

# Export schema and data from database ICareMVCMasterdac
$d.exportbacpac("c:\temp\ICareMVCMasterdac.bacpac", "ICareMVCMasterdac")

# Load dacpac from file & deploy to database named pubsnew
$dp = [Microsoft.SqlServer.Dac.DacPackage]::Load("c:\temp\ICareMVCMaster.dacpac")
$d.deploy($dp, "New_ICareMVCMaster")

# Load bacpac from file & import to database named pubsdac2
$bp = [Microsoft.SqlServer.Dac.BacPackage]::Load("c:\temp\ICareMVCMasterdac.bacpac")
$d.importbacpac($bp, "New_ICareMVCMaster2")




# clean up event
unregister-event -source "msg"
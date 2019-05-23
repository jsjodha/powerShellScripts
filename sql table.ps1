function GetData($dbName){
    try{ 
        # Configure connection string
        $con = New-Object System.Data.SqlClient.SqlConnection("Data Source=.;Integrated Security=true;Initial Catalog=$dbName");
        # Create two sql statements for the tables
        $q1 = "SELECT * FROM dbo.DBConnections";
        # Create dataset objects
        $resultset1 = New-Object "System.Data.DataSet" "myDs";

        # Run query 1 and fill resultset1
        $data_adap = new-object "System.Data.SqlClient.SqlDataAdapter" ($q1, $con);
        $data_adap.Fill($resultset1) | Out-Null;
        # Get data table (only first table will be compared).
        [System.Data.DataTable]$dataset1 = $resultset1.Tables[0];

        return $dataset1    
    }
    finally{
        # Clean up
        $data_adap.Dispose();
        $con.Close();
        $con.Dispose();
    }
}


## Configure connection string
#$con = New-Object System.Data.SqlClient.SqlConnection("Data Source=.;Integrated Security=true;Initial Catalog=ICareMVCMaster");
## Create two sql statements for the tables
#$q1 = "SELECT * FROM dbo.DBConnections";
#$q2 = "SELECT * FROM dbo.DBConnections";
## Create dataset objects
#$resultset1 = New-Object "System.Data.DataSet" "myDs";
#$resultset2 = New-Object "System.Data.DataSet" "myDs";
## Run query 1 and fill resultset1
#$data_adap = new-object "System.Data.SqlClient.SqlDataAdapter" ($q1, $con);
#$data_adap.Fill($resultset1) | Out-Null;
## Run query 2 and fill resultset2
#$data_adap = new-object "System.Data.SqlClient.SqlDataAdapter" ($q2, $con);
#$data_adap.Fill($resultset2) | Out-Null;
 
# Get data table (only first table will be compared).
#[System.Data.DataTable]$dataset1 = $resultset1.Tables[0];
#[System.Data.DataTable]$dataset2 = $resultset2.Tables[0];
 
# Compare tables
$dataset1 = GetData('ICareMVcMaster')

write-host $dataset1 |Format-list *


$dataset2 = GetDAta('New_IcareMvcMaster')

$diff = Compare-Object $dataset1 $dataset2;
# Are there any differences?
if($diff -eq $null)
{
	Write-Host "The resultsets are the same.";
}
else
{
	Write-Host "The resultsets are different.";
}
 
# Clean up
#$dataset1.Dispose();
#$dataset2.Dispose();
#$resultset1.Dispose();
#$resultset2.Dispose();
#$data_adap.Dispose();
#$con.Close();
#$con.Dispose();

 public class SqlSchemaCompare
    {
        //#r "C:\Program Files\Microsoft SQL Server\140\DAC\bin\Microsoft.SqlServer.Dac.Extensions.dll"
       public void Compare()
        {
            var csb = new SqlConnectionStringBuilder
            {
                DataSource = ".",
                InitialCatalog = "ICareMVCMaster",
                IntegratedSecurity = true
            };
            var bacPacFile = @"C:\temp\icaremvcmaster.dacpac";
            var s = new Microsoft.SqlServer.Dac.DacServices(csb.ConnectionString);
            s.Extract(bacPacFile, "IcareMVCMaster", "Test Application", new Version("1.1.1.1"));
            var sourceDacpac = new SchemaCompareDacpacEndpoint(bacPacFile);

            var csb2 = new SqlConnectionStringBuilder
            {
                DataSource = ".",
                InitialCatalog = "New_ICareMVCMaster",
                IntegratedSecurity = true
            };
            var targetDatabase = new SchemaCompareDatabaseEndpoint(csb2.ToString());

            var comparison = new SchemaComparison(sourceDacpac, targetDatabase);
            // Persist comparison file to disk in Schema Compare (.scmp) format
            comparison.SaveToFile(@"C:\temp\mycomparison.scmp");

            // Load comparison from Schema Compare (.scmp) file
            comparison = new SchemaComparison(@"C:\temp\mycomparison.scmp");
            SchemaComparisonResult comparisonResult = comparison.Compare();
            
            // Find the change to table1 and exclude it.
            //foreach (SchemaDifference difference in comparisonResult.Differences)
            //{
            //    if (difference.TargetObject.Name != null &&
            //        difference.TargetObject.Name.HasName &&
            //        difference.TargetObject.Name.Parts[1] == "DbConnections")
            //    {
            //        comparisonResult.Exclude(difference);
            //        break;
            //    }
            //}


            // Publish the changes to the target database
            //SchemaComparePublishResult publishResult = comparisonResult.PublishChangesToTarget();
            var publishResult = comparisonResult.GenerateScript(".");
            Console.WriteLine(publishResult.MasterScript);
            Console.WriteLine(publishResult.Script);
            Console.WriteLine(publishResult.Success ? "Publish succeeded." : "Publish failed.");
        }

      
    }
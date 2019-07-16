#r "nuget:Microsoft.PowerShell.5.1.ReferenceAssemblies/1.0.0"
using System.Management.Automation;
using System.Management.Automation.Runspaces;

public class ImpersonateScript{



public void ImpersonateUser(string userName, string domain, string password){


}
/// <summary>
/// Executes a PowerShell script synchronously with script output.
/// </summary>
public void Execute(string scriptfile, Dictionary<string, string> scriptargs)
{

    try
    {
        RunspaceConfiguration runspaceConfiguration = RunspaceConfiguration.Create();

        Runspace runspace = RunspaceFactory.CreateRunspace(runspaceConfiguration);
        runspace.Open();

        RunspaceInvoke scriptInvoker = new RunspaceInvoke(runspace);

        Pipeline pipeline = runspace.CreatePipeline();

        //Here's how you add a new script with arguments
        Command myCommand = new Command(scriptfile);
        foreach (var kvp in scriptargs)
        {
            var param = new CommandParameter(kvp.Key, kvp.Value.ToString());
            myCommand.Parameters.Add(param);
        }


        pipeline.Commands.Add(myCommand);

        // Execute PowerShell script
        var results = pipeline.Invoke();
        Console.WriteLine("Results:");
        foreach (var rs in results)
        {
            Console.WriteLine(rs);
        }
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine("Exception while executing PSScript: " + ex.ToString());
    }
}


/// <summary>
/// Executes a PowerShell script asynchronously with script output and event handling.
/// </summary>
public void ExecuteAsynchronously(string scriptFile, Dictionary<string, object> scriptargs, int timeOut = 5)
{

    if (!System.IO.File.Exists(scriptFile))
        throw new FileNotFoundException("script file not found");

    var scriptText = System.IO.File.ReadAllText(scriptFile);



    using (PowerShell PowerShellInstance = PowerShell.Create())
    {
        // this script has a sleep in it to simulate a long running script
        //PowerShellInstance.AddScript("$s1 = 'test1'; $s2 = 'test2'; $s1; write-error 'some error';start-sleep -s 7; $s2");

        PowerShellInstance.AddScript(scriptText);
        foreach (var kvp in scriptargs)
        {
            PowerShellInstance.AddParameter(kvp.Key, kvp.Value);
        }
        // prepare a new collection to store output stream objects
        PSDataCollection<PSObject> outputCollection = new PSDataCollection<PSObject>();
        outputCollection.DataAdded += outputCollection_DataAdded;

        // the streams (Error, Debug, Progress, etc) are available on the PowerShell instance.
        // we can review them during or after execution.
        // we can also be notified when a new item is written to the stream (like this):
        PowerShellInstance.Streams.Error.DataAdded += Error_DataAdded;

        var startTime = DateTime.Now;
        // begin invoke execution on the pipeline
        // use this overload to specify an output stream buffer
        IAsyncResult result = PowerShellInstance.BeginInvoke<PSObject, PSObject>(null, outputCollection);


        // do something else until execution has completed.
        // this could be sleep/wait, or perhaps some other work
        while (result.IsCompleted == false)
        {
            Console.WriteLine("Waiting for pipeline to finish...");
            Thread.Sleep(1000);
            var timeSpent = DateTime.Now - startTime;
            if (timeSpent.Minutes >= timeOut)
            {
                PowerShellInstance.Dispose();
                break;
            }
        }

        Console.WriteLine("Execution has stopped. The pipeline state: " + PowerShellInstance.InvocationStateInfo.State);

        foreach (PSObject outputItem in outputCollection)
        {
            //TODO: handle/process the output items if required
            Console.WriteLine(outputItem.BaseObject.ToString());
        }
    }
}

/// <summary>
/// Event handler for when data is added to the output stream.
/// </summary>
/// <param name="sender">Contains the complete PSDataCollection of all output items.</param>
/// <param name="e">Contains the index ID of the added collection item and the ID of the PowerShell instance this event belongs to.</param>
void outputCollection_DataAdded(object sender, DataAddedEventArgs e)
{
    // do something when an object is written to the output stream
    Console.WriteLine("Object added to output.");
}

/// <summary>
/// Event handler for when Data is added to the Error stream.
/// </summary>
/// <param name="sender">Contains the complete PSDataCollection of all error output items.</param>
/// <param name="e">Contains the index ID of the added collection item and the ID of the PowerShell instance this event belongs to.</param>
void Error_DataAdded(object sender, DataAddedEventArgs e)
{
    // do something when an error is written to the error stream
    Console.WriteLine("An error was written to the Error stream!");
}
}
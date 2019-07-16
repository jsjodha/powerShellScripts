using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApp1
{
    class Program
    {
        static void Main(string[] args)
        {

            var procs = System.Diagnostics.Process.GetProcesses();

            foreach (Process item in procs)
            {
                Console.WriteLine(item.ProcessName);
            }
        }
    }
}

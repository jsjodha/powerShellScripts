
// This compares the contents of two files to find any records 
// that are in one file but not in the other file.
// Note that the order of the records in the files is immaterial.

// A positive value in the integer part of the dictionary
// signifies that the record is found in file A
// A negative value means file B
Dictionary<int, string> Comparer = new Dictionary<int, string>();
string line;
int records = 0; // only used for progress reporting

// Load the first file into the dictionary
Console.WriteLine("Loading file A");
using (StreamReader sr = new StreamReader(@"C:\Temp\HashKeyMap.src"))
{
    while (sr.Peek() >= 0)
    {
        // Progress reporting
        if (++records % 10000 == 0)
            Console.Write("{0}%...\r", sr.BaseStream.Position * 100 / sr.BaseStream.Length);

        string[] lineValues = sr.ReadLine().Split(',');
        int key = Convert.ToInt32(lineValues.First());
        string value = lineValues.Last();
        if (!Comparer.ContainsKey(key))
            Comparer[key] = value;
    }
}
Console.WriteLine("Loaded");

// Load the second file, hopefully zeroing out the dictionary values
Console.WriteLine("Loading file B");
using (StreamReader sr = new StreamReader(@"C:\Temp\HashKeyMap.trg"))
{
    while (sr.Peek() >= 0)
    {
        // Progress reporting
        if (++records % 10000 == 0)
            Console.Write("{0}%...\r", sr.BaseStream.Position * 100 / sr.BaseStream.Length);

        var lineValues = sr.ReadLine().Split(',');
        int key = Convert.ToInt32(lineValues.First());
        var val = lineValues.Last();
        if (Comparer.ContainsKey(key))
        {
            var keyVal = Comparer[key];
            if (string.Equals(val, keyVal, StringComparison.CurrentCultureIgnoreCase))
                Comparer.Remove(key);
            else
                Comparer[key] = string.Format("{0} vs {1}", keyVal, val);
        }
    }
}
Console.WriteLine("Loaded");

// List any mismatches
int mismatches = 0;
Console.WriteLine("Diffrences found :" + Comparer.Count);
var sw = new System.IO.StreamWriter(@"C:\Temp\HashKeyDiff.rs", false);
foreach (KeyValuePair<int, string> kvp in Comparer)
{
    mismatches++;
    string dataDiff = string.Format("{0} | {1}", kvp.Key, kvp.Value);
    sw.WriteLine(dataDiff);
}
if (mismatches == 0)
    Console.WriteLine("No mismatches found");

// How much ram did this use?
Console.WriteLine(
  "Used {0} MB of memory (private bytes) to compare {1} records",
  System.Diagnostics.Process.
   GetCurrentProcess().PrivateMemorySize64 / 1024 / 1024,
  records);

// Free the memory to the GC explicitly in case you use this in other code
// This isn't essential, it just returns the memory faster in my tests.
Comparer.Clear();
Comparer = null;
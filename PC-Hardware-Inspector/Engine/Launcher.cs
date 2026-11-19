using System;
using System.Diagnostics;
using System.IO;

class Program
{
    static int Main()
    {
        Console.Title = "PC-Hardware-Inspector";
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string script = Path.Combine(dir, "Engine", "PC-Hardware-Inspector.ps1");
        if (!File.Exists(script))
        {
            script = Path.Combine(dir, "PC-Hardware-Inspector.ps1");
        }

        if (!File.Exists(script))
        {
            Console.WriteLine("Missing file: " + script);
            Console.WriteLine("Keep the Engine folder next to this program.");
            Console.WriteLine();
            Console.WriteLine("Press any key to close...");
            Console.ReadKey(true);
            return 1;
        }

        ProcessStartInfo psi = new ProcessStartInfo("powershell.exe",
            "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\"");
        psi.UseShellExecute = false;

        using (Process p = Process.Start(psi))
        {
            p.WaitForExit();
        }

        Console.WriteLine();
        Console.WriteLine("Press any key to close...");
        Console.ReadKey(true);
        return 0;
    }
}

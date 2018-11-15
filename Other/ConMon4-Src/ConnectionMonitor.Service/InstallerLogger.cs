using System; 
using System.Collections.Generic; 
using System.Text; 
using System.IO;

namespace ConnectionMonitor.Service
{
    /// <summary> 
    /// Enables a quick and easy method of debugging custom actions. 
    /// </summary> 
    class InstallerLogger
    {
        const string FileName = "ConnectionMonitorService.Deployment.log";
        readonly string _filePath;

        public InstallerLogger(string primaryOutputPath)
        {
            var dir = Path.GetDirectoryName(primaryOutputPath);
            _filePath = Path.Combine(dir, FileName);
        }

        public void Print(Exception ex)
        {
            File.AppendAllText(_filePath, "Error: " + ex.Message + Environment.NewLine +
                    "Stack Trace: " + Environment.NewLine + ex.StackTrace + Environment.NewLine);
        }

        public void Print(string format, params object[] args)
        {
            var text = String.Format(format, args) + Environment.NewLine;

            File.AppendAllText(_filePath, text);
        }

        public void PrintLine() { Print(""); }
    }
}
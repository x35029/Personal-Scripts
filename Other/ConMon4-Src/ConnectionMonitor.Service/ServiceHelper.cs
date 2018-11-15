using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ServiceProcess;
using System.Diagnostics;
using Microsoft.Win32;

namespace ConnectionMonitor.Service
{
    class ServiceHelper
    {
        public static void SetServiceStartupType(string serviceName, string friendlyName, string newStartType)
        {
            ServiceController sc = new ServiceController(serviceName);
            if (sc != null)
            {
                    ProcessStartInfo psi = new ProcessStartInfo(Environment.SystemDirectory + "\\sc.exe");
                    psi.Arguments = "config " + serviceName + " start= " + newStartType;
                    psi.WindowStyle = ProcessWindowStyle.Hidden;

                    Process sc2 = Process.Start(psi);
                    sc2.WaitForExit();

                    if (sc2.ExitCode != 0)
                    {
                        throw new ApplicationException("Could not set the startup type for the " + friendlyName + " Service.");
                    }
            }           
        }

        public static void StartService(string serviceName, string friendlyName)
        {
            // if service is stopped, attempt to start it.  If it is disabled, attempt to set it to automatic.
            ServiceController sc = new ServiceController(serviceName);
            if (sc != null && (sc.Status != ServiceControllerStatus.Running || sc.Status == ServiceControllerStatus.StartPending))
            {

                
                // Service Startup Types:
                //  4 = Disabled
                //  3 = Manual
                //  2 = Automatic
                int startupType = GetStartupType(sc.ServiceName);
                if (startupType == 4)
                {
                    SetServiceStartupType(serviceName, friendlyName, "auto");
                }

                try
                {
                    sc.Start();
                    sc.WaitForStatus(ServiceControllerStatus.Running);
                }
                catch (InvalidOperationException invalidOperationException)
                {
                    throw new ApplicationException("The " + friendlyName + " service could not be started.", invalidOperationException);
                }
            }
        }

        private static int GetStartupType(string serviceName)
        {
            //HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services
            using (RegistryKey service = Registry.LocalMachine.OpenSubKey("SYSTEM\\CurrentControlSet\\Services\\" + serviceName))
            {
                if (service == null)
                    throw new NullReferenceException("Service does not exist");

                return Convert.ToInt32(service.GetValue("Start"));
            }
        }

    }
}

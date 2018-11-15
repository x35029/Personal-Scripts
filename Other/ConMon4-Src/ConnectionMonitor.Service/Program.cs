using System;
using System.Collections.Generic;
using System.ServiceProcess;
using System.Text;
using Microsoft.NetworkInterfaceControl;
using Microsoft.Practices.EnterpriseLibrary.Logging;

namespace ConnectionMonitor.Service
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main(string[] args)
        {
            const string MemberName = "Main";

            using (new Tracer(MemberName))
            {
                try
                {
                    if (args.Length > 0)
                    {
                        if (String.Compare(args[0], "-regadapters", true) == 0 ||
                            String.Compare(args[0], "/regadapters", true) == 0)
                        {
                            ConMonInstaller installer = new ConMonInstaller();
                            installer.UpdateAppConfigFile();
                        }
                    }
                    else
                    {
                        ServiceBase[] ServicesToRun;

                        // More than one user Service may run within the same process. To add
                        // another service to this process, change the following line to
                        // create a second service object. For example,
                        //
                        //   ServicesToRun = new ServiceBase[] {new Service1(), new MySecondUserService()};
                        //
                        ServicesToRun = new ServiceBase[] { new ConMonService() };

                        ServiceBase.Run(ServicesToRun);
                    }
                }
                catch (ConnectionMonitorException cme)
                {
                    throw cme;
                }
                catch (Exception ex)
                {
                    ConnectionMonitorException cme = new ConnectionMonitorException(
                        "Exception caught in " + MemberName, ex);
                    Logger.Write(ex);
                    throw ex;
                }
            }
        }
    }
}
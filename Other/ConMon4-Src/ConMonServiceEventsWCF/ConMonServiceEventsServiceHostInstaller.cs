using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace ConMonServiceEventsWCF
{
    /// <summary>
    /// Installs ConMonServiceEventsHost as a Windows service
    /// </summary>
    [RunInstaller(true)]
    public class ConMonServiceEventsServiceHostInstaller : Installer
    {
        /// <summary>
        /// Service process installer instance used to install the service into
        /// </summary>
        private ServiceProcessInstaller process;
        /// <summary>
        /// Service installer instance used to install the service
        /// </summary>
        private ServiceInstaller service;

        /// <summary>
        /// Constructor
        /// </summary>
        public ConMonServiceEventsServiceHostInstaller()
        {
            this.process = new ServiceProcessInstaller();
            this.process.Account = ServiceAccount.LocalSystem;
            this.service = new ServiceInstaller();
            this.service.ServiceName = "ConMonServiceEvents";
            this.service.DisplayName = "ConMonServiceEvents";
            this.service.Description = "Hosts WCF Service ConMonServiceEvents to allow Connection Monitor service to publish events to other applications.";
            this.service.StartType = ServiceStartMode.Automatic;
            Installers.Add(this.process);
            Installers.Add(this.service);

            this.AfterInstall += new InstallEventHandler(ConMonServiceEventsServiceHostInstaller_AfterInstall);
        }

        /// <summary>
        /// Fires after the service is installed
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        void ConMonServiceEventsServiceHostInstaller_AfterInstall(object sender, InstallEventArgs e)
        {
            ServiceController controller = null;
            try
            {
                controller = new ServiceController("ConMonServiceEvents");
                controller.Start();
                controller.Dispose();
                controller = null;
            }
            finally
            {
                if (controller != null)
                {
                    controller.Dispose();
                    controller = null;
                }
            }
        }
    }
}

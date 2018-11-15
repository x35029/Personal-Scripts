using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ServiceModel;
using System.ServiceProcess;
using Microsoft.Practices.EnterpriseLibrary.Logging;
using System.Diagnostics;

namespace ConMonServiceEventsWCF
{
    /// <summary>
    /// Hosts the ConMonServiceEvents WCF service in Windows
    /// </summary>
    public class ConMonServiceEventsServiceHost : ServiceBase
    {
        /// <summary>
        /// Host instance
        /// </summary>
        ServiceHost host = null;

        /// <summary>
        /// Constructor
        /// </summary>
        public ConMonServiceEventsServiceHost()
        {
            this.ServiceName = "ConMonServiceEvents";
        }

        /// <summary>
        /// Runs the service host
        /// </summary>
        public static void Main()
        {
            try
            {
                ServiceBase.Run(new ConMonServiceEventsServiceHost());
            }
            catch (Exception ex)
            {
                Logger.Write(ex);
                throw;
            }
        }

        /// <summary>
        /// Start event handler for the hosted service.
        /// </summary>
        /// <param name="args"></param>
        protected override void OnStart(string[] args)
        {
            base.OnStart(args);

            this.StopAndCleanupHost();

            this.StartupHost();
        }
        
        /// <summary>
        /// Stop event handler for the hosted service
        /// </summary>
        protected override void OnStop()
        {
            this.StopAndCleanupHost();

            base.OnStop();
        }

        /// <summary>
        /// Fires when a power event on the computer is happening
        /// </summary>
        /// <param name="powerStatus"></param>
        /// <returns>Boolean indicating whether to continue the powerevent</returns>
        protected override bool OnPowerEvent(PowerBroadcastStatus powerStatus)
        {
            const string MemberName = "OnPowerEvent";

            using (new Tracer(MemberName))
            {
                try
                {
                    LogMessage("Power mode event fired" + powerStatus.ToString() + ". Determining action to take", TraceEventType.Information);

                    if (powerStatus == PowerBroadcastStatus.ResumeAutomatic || 
                        powerStatus == PowerBroadcastStatus.ResumeCritical || 
                        powerStatus == PowerBroadcastStatus.ResumeSuspend)
                    {
                        LogMessage("System is resuming from hibernation! Restarting ConMon Service Events", TraceEventType.Verbose);

                        this.StartupHost();
                    }
                    else if (powerStatus == PowerBroadcastStatus.Suspend)
                    {
                        LogMessage("System is hibernating! Stopping ConMon Service Events", TraceEventType.Verbose);
                        StopAndCleanupHost();
                    }

                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                }
            }

            return base.OnPowerEvent(powerStatus);
        }

        #region Host Management
        /// <summary>
        /// Makes sure that a host instance is closed and null
        /// </summary>
        private void StopAndCleanupHost()
        {
            if (this.host != null)
            {
                LogMessage("Cleaning up host!", TraceEventType.Information);
                this.host.Close();
                this.host = null;
            }
        }

        /// <summary>
        /// Starts up the host instance
        /// 
        /// </summary>
        private void StartupHost()
        {
            LogMessage("Starting up host!", TraceEventType.Information);
            this.host = new ServiceHost(typeof(ConMonServiceEvents));
            this.host.Open();
        }
        #endregion

        protected override void OnPause()
        {
            this.StopAndCleanupHost();
            base.OnPause();
        }

        protected override void OnContinue()
        {
            this.StopAndCleanupHost();
            this.StartupHost();
            base.OnContinue();
        }

        protected override void OnShutdown()
        {
            this.StopAndCleanupHost();
            base.OnShutdown();
        }
        /// <summary>
        /// Write a message to the log file
        /// </summary>
        /// <param name="msg">Message Text to write</param>
        /// <param name="severity">Severity of the message/error</param>
        private void LogMessage(string msg, TraceEventType severity)
        {
            Logger.Write(msg, "General", 1, 1, severity);
        }

        private void InitializeComponent()
        {
            // 
            // ConMonServiceEventsServiceHost
            // 
            this.CanHandlePowerEvent = true;
            this.CanPauseAndContinue = true;
            this.CanShutdown = true;

        }
    }
}

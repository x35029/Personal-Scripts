using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Net.NetworkInformation;
using System.Reflection;
using System.ServiceProcess;
using System.Text;
using System.Threading;
using System.Xml;
using Microsoft.NetworkInterfaceControl;
using Microsoft.Win32;
using System.Configuration;
using Microsoft.Practices.EnterpriseLibrary.Logging;
using ConnectionMonitor.Configuration;
using System.ServiceModel;
using ConnectionMonitor.Service.ConMonServiceEventsWCFService;

namespace ConnectionMonitor.Service
{

    /// <summary>
    /// Service responsible to make sure that only one network connection is enabled at a time
    /// </summary>
    public partial class ConMonService : ServiceBase
    {
        /// <summary>
        /// List of network interface controllers monitored by this service read from the configuration file.
        /// </summary>
        private NetworkInterfaceController nicController;
        /// <summary>
        /// Registry key for this service [SHOULD NOT BE USED]
        /// </summary>
        private const string conMonRegKey = "SOFTWARE\\Microsoft\\Connection Monitor";
        /// <summary>
        /// Flight mode locking instance [NOT REALLY USED]
        /// </summary>
        private static object _flightModeLock  = new object();
        /// <summary>
        /// Network being evaluated lock instance
        /// </summary>
        private static object _networkEvalLock = new object();
        /// <summary>
        /// Client used to communicate with the WCF service to publish events
        /// </summary>
        private ConMonServiceEventsClient ConMonServiceEventsWCFServiceClient = null;
        /// <summary>
        /// Context instance to be used for callback interface for WCF service to publish events
        /// </summary>
        private InstanceContext ConMonServiceEventsWCFServiceCallbackContext = null;

        /// <summary>
        /// flag to denote that the event is bound
        /// </summary>
        private bool _eventBound = false;

        #region Binding and Unbinding events
        
        private void BindEvent()
        {
            if (!_eventBound)
            {
                LogMessage("Listening to network address change messages!", TraceEventType.Information);
                NetworkChange.NetworkAddressChanged += new NetworkAddressChangedEventHandler(NetworkAddressChanged);
                _eventBound = true;
            }
            else
            {
                LogMessage("Already listening to network address change events!", TraceEventType.Information);
            }
        }

        private void UnbindEvent()
        {
            if (_eventBound)
            {
                LogMessage("Ignoring network address change messages!", TraceEventType.Information);
                NetworkChange.NetworkAddressChanged -= new NetworkAddressChangedEventHandler(NetworkAddressChanged);
                _eventBound = false;
            }
            else
            {
                LogMessage("Already ignoring network address change events!", TraceEventType.Information);
            }
        }
#endregion

        #region Service Events
        /// <summary>
        /// Fired when the service is started
        /// </summary>
        /// <param name="args"></param>
        protected override void OnStart(string[] args)
        {
            const string MemberName = "OnStart";

            using (new Tracer(MemberName))
            {
                try
                {
                    this.InitializeWCFServiceEventPublisher();

                    this.ConMonServiceEventsWCFServiceClient.ServiceStarted();

                    LogMessage("Service Started", TraceEventType.Information);

                    //Set this service to delay start
                    ServiceHelper.SetServiceStartupType("ConMon", "Connection Monitor", "delayed-auto");

                    //Check for services that need to be started
                    CheckForDependentServices();

                    PopulateWirelessNicsAndController(false);

                    Thread _networkEvalThread = new Thread(new ParameterizedThreadStart(ConMonService.ThreadStart));
                    _networkEvalThread.Start(this);

                    BindEvent();
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                }
                catch (Exception ex)
                {
                    ConnectionMonitorException cme = new ConnectionMonitorException(
                        "Exception caught in " + MemberName, ex);
                    Logger.Write(ex);
                }
            }

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
                    bool runResume = true;

                    this.EnsureWCFClient();
                    this.ConMonServiceEventsWCFServiceClient.ServicePowerEvent(powerStatus);

                    bool resumeMode = false;

                    LogMessage("Power mode event fired. Checking dependent services.", TraceEventType.Information);

                    if (powerStatus == PowerBroadcastStatus.ResumeAutomatic || powerStatus == PowerBroadcastStatus.ResumeCritical || powerStatus == PowerBroadcastStatus.ResumeSuspend)
                    {
                        LogMessage("System is resuming from hibernation! Repopulating wireless NICS and controllers", TraceEventType.Verbose);

                        resumeService(resumeMode);
                        BindEvent();
                    }
                    else if (powerStatus == PowerBroadcastStatus.Suspend)
                    {
                        LogMessage("Service is going into suspend mode.", TraceEventType.Information);

                        UnbindEvent();

                        // Shutdown WCF service used to publish events
                        CleanupWCFServiceEventPublisher();
                       
                    }
               }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                }
            }

            return base.OnPowerEvent(powerStatus);
        }

        /// <summary>
        /// Service was continued from a pause
        /// </summary>
        protected override void OnContinue()
        {
            base.OnContinue();

            const string MemberName = "OnContinue";

            using (new Tracer(MemberName))
            {
                try
                {
                    InitializeWCFServiceEventPublisher();

                    this.ConMonServiceEventsWCFServiceClient.ServiceRestarted();

                    LogMessage("Service continued. Checking dependent services.", TraceEventType.Information);

                    resumeService(true);
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                }
            }
        }

        /// <summary>
        /// Service was paused.
        /// </summary>
        protected override void OnPause()
        {
            base.OnPause();

            const string MemberName = "OnPause";

            using (new Tracer(MemberName))
            {
                try
                {
                    this.EnsureWCFClient();
                    this.ConMonServiceEventsWCFServiceClient.ServicePaused();

                    LogMessage("Service paused.", TraceEventType.Information);
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                }
                finally
                {
                    CleanupWCFServiceEventPublisher();
                }
            }
        }

        /// <summary>
        /// Service was stopped
        /// </summary>
        protected override void OnStop()
        {
            const string MemberName = "OnStop";

            using (new Tracer(MemberName))
            {
                try
                {
                    this.EnsureWCFClient();
                    this.ConMonServiceEventsWCFServiceClient.ServiceStopped();
                    LogMessage("Service Stopped", TraceEventType.Information);

                    NetworkChange.NetworkAddressChanged -= NetworkAddressChanged;
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                }
                finally
                {
                    this.CleanupWCFServiceEventPublisher();
                }
            }
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Determines if the machine is in flight mode
        /// </summary>
        /// <returns>Returns true if in flight mode; otherwise returns false</returns>
        public static bool IsInFlightMode()
        {
            // cgreene 5 Aug 2009 - I am completely punting here.  This commented code below
            // has been there for a while.  But it's not ever really been requested and hasn't
            // been used thus far.  In the 
            // meantime, we are trying to make a single MSI package that will work on both
            // x86 and x64.  We discovered the registry key written by the 32-bit MSI is
            // written under HKLM\Software\Wow6432Node\. So BWilkens and I found that this
            // would force us to have 2 separate packages.  One for x86 and one for x64.
            // So in weighing the options here, 
            // my choice is to hardcode a false return here & revisit later if someone ever
            // requests this feature.
            //lock (_flightModeLock)
            //{
            //    using (RegistryKey rk = Registry.LocalMachine.OpenSubKey(conMonRegKey))
            //    {
            //        return ((Int32)rk.GetValue("FlightMode") == 1);
            //    }
            //}
            return false;
        }
        #endregion

        #region Private Methods
        /// <summary>
        /// Makes sure the client instance is instanced
        /// </summary>
        private void EnsureWCFClient()
        {
            // If not in open state, open it
            if (this.ConMonServiceEventsWCFServiceClient != null && this.ConMonServiceEventsWCFServiceClient.State != CommunicationState.Opened)
            {
                this.Dispose();
                this.ConMonServiceEventsWCFServiceClient = null;
                this.InitializeWCFServiceEventPublisher();
            }

            // If closed or not instantiated, then 
            if (this.ConMonServiceEventsWCFServiceClient == null || this.ConMonServiceEventsWCFServiceClient != null && (this.ConMonServiceEventsWCFServiceClient.State == CommunicationState.Closed))
            {
                this.ConMonServiceEventsWCFServiceClient = null;
                this.InitializeWCFServiceEventPublisher();
            }
        }

        /// <summary>
        /// Initialize WCF service to publish events
        /// </summary>
        private void InitializeWCFServiceEventPublisher()
        {
            if (this.ConMonServiceEventsWCFServiceClient != null || this.ConMonServiceEventsWCFServiceCallbackContext != null)
            {
                this.CleanupWCFServiceEventPublisher();
            }

            this.ConMonServiceEventsWCFServiceCallbackContext = new InstanceContext(new ConMonServiceEventsWCFServiceCallback());
            this.ConMonServiceEventsWCFServiceClient = new ConMonServiceEventsClient(this.ConMonServiceEventsWCFServiceCallbackContext);
        }

        /// <summary>
        /// Cleanup WCF service instances
        /// </summary>
        private void CleanupWCFServiceEventPublisher()
        {
            try
            {

                if (this.ConMonServiceEventsWCFServiceCallbackContext != null)
                {
                    this.ConMonServiceEventsWCFServiceCallbackContext.Close();
                    this.ConMonServiceEventsWCFServiceCallbackContext = null;
                }

                if (this.ConMonServiceEventsWCFServiceClient != null)
                {
                    this.ConMonServiceEventsWCFServiceClient.Close();
                    this.ConMonServiceEventsWCFServiceClient = null;
                }
            }
            catch (Exception ex)
            {
                Logger.Write(ex);
            }
        }

        /// <summary>
        /// Method that keeps the service up and running looking for IPaddress changes.
        /// </summary>
        /// <param name="service">Instance of service</param>
        private static void ThreadStart(object service)
        {
            const string MemberName = "ThreadStart";
            using (new Tracer(MemberName))
            {
                try
                {
                    ConMonService cms = (ConMonService)service;
                    cms.EvaluateNetworkState();
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                }
            }
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

        /// <summary>
        /// Fires when the network address changes
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        void NetworkAddressChanged(object sender, EventArgs e)
        {
            const string MemberName = "NetworkAddressChanged";

            using (new Tracer(MemberName))
            {
                try
                {
                    this.EnsureWCFClient();
                    this.ConMonServiceEventsWCFServiceClient.IPAddressChanged();

                    EvaluateNetworkState();
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                }
            }
        }

        /// <summary>
        /// Checks to see what type of Nic fired the IPAddress change event.
        /// </summary>
        void EvaluateNetworkState()
        {
            const string MemberName = "EvaluateNetworkState";

            using (new Tracer(MemberName))
            {
                try
                {
                    lock (_networkEvalLock)
                    {
                        if (nicController == null)
                        {
                            throw new Exception("nicController instance is null!");
                        }

                        if (IsInFlightMode())
                        {
                            bool success = nicController.Disable();
                        }
                        else
                        {
                            if (nicController.Wired)
                            {
                                LogMessage("Controller has determined that a wired connection is active! Disabling wireless!", TraceEventType.Verbose);
                                bool success = nicController.Disable();
                            }
                            else
                            {
                                LogMessage("Controller has determined that no wired connection is active! Enabling wireless!", TraceEventType.Verbose);
                                nicController.NICEnabled += new NetworkInterfaceController.OnNICEnabled(this.NICControllerNICEnabled);
                                bool success = nicController.Enable();
                                nicController.NICEnabled -= this.NICControllerNICEnabled;
                            }
                        }
                    }
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                    throw cme;
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                    throw ex;
                }
            }
        }

        /// <summary>
        /// Fires when an instance of NICController enables a device
        /// </summary>
        /// <param name="deviceName">Name of device enabled</param>
        private void NICControllerNICEnabled(string deviceName)
        {
            this.ConMonServiceEventsWCFServiceClient.NICEnabled(deviceName);
        }

        /// <summary>
        /// Starts each dependent service listed in the configuration file
        /// </summary>
        void CheckForDependentServices()
        {
            const string MemberName = "CheckForDependentServices";

            try
            {
                List<string> dependentSevices = new List<string>();
                DataSection ds = (DataSection)ConfigurationManager.GetSection("DependentServiceList");

                if (ds.Items == null || ds.Items.Count == 0)
                {
                    ConnectionMonitorException cme = new ConnectionMonitorException(
                            "No Dependent services defined in the configuration file! " + MemberName);
                }

                for (int i = 0; i < ds.Items.Count; i++)
                {
                    string name = ds.Items[i].Data;
                    try
                    {
                        ServiceHelper.StartService(name, name);
                        dependentSevices.Add(name);
                    }
                    catch (Exception ex)
                    {
                        ConnectionMonitorException cme = new ConnectionMonitorException(
                            "Cannot start dependent service " + name, ex);
                        Logger.Write(cme);
                        throw cme;
                    }
                }

                if (dependentSevices != null && dependentSevices.Count > 0)
                {
                    this.EnsureWCFClient();
                    this.ConMonServiceEventsWCFServiceClient.DependentServicesChecked(dependentSevices.ToArray());
                }
            }
            catch (ConnectionMonitorException cme)
            {
                Logger.Write(cme);
                throw cme;
            }
            catch (Exception ex)
            {
                Logger.Write(ex);
                throw;
            }
        }

        /// <summary>
        /// Builds an internal list of NICs and if passed true for forceUpdate, will update the wireless NIC entry in the configuration file.
        /// </summary>
        /// <param name="forceUpdate">Boolean if true, forces the application to update the configuration with the name of the wireless NIC installed on the computer.</param>
        private void PopulateWirelessNicsAndController(bool forceUpdate)
        {
            const string MemberName = "PopulateWirelessNicsAndController";

            using (new Tracer(MemberName))
            {
                try
                {
                    if ((forceUpdate == true))
                    {
                        // No wireless adapters were found during installation.
                        // Perhaps it was disabled in the BIOS upon install.  
                        // Let's try again...
                        ConMonInstaller installer = new ConMonInstaller();
                        installer.UpdateAppConfigFile();
                    }
                    string vpnExceptionList = GetVPNExceptionList();
                    MonitoredDevice[] monitoredDevices = ReadMonitoredDevicesFromConfig();
                    nicController = new NetworkInterfaceController(eventLog, vpnExceptionList, monitoredDevices);

                    // Build list of NIC Names and publish NICsFound event to WCF service
                    List<string> nics = new List<string>();
                    foreach (MonitoredDevice device in monitoredDevices)
                    {
                        nics.Add(device.Name);
                    }
                    if (nics != null && nics.Count > 0)
                    {
                        this.ConMonServiceEventsWCFServiceClient.NICsFound(nics.ToArray());
                    }
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                    throw cme;
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                    throw ex;
                }
            }
        }

        /// <summary>
        /// Performs checking for dependent service and repopulates the internal list of NICs called from power events.
        /// </summary>
        /// <param name="isFromPowerModeResume">Boolean to indicate that power event was a resume service and to repopulate the internal list of NICs and write the computer's wireless NIC to the configuration file.</param>
        private void resumeService(bool isFromPowerModeResume)
        {
            //Check for services that need to be started
            CheckForDependentServices();

            if (isFromPowerModeResume)
            {
                PopulateWirelessNicsAndController(true);
            }

            EvaluateNetworkState();
        }

        /// <summary>
        /// Obtain list of monitored decvices that are to be included in list of network adapters that can be enabled/disabled
        /// </summary>
        /// <returns>Array of Adapter Names to be monitored</returns>
        private static MonitoredDevice[] ReadMonitoredDevicesFromConfig()
        {
            const string MemberName = "ReadMonitoredDevicesFromConfig";

            using (new Tracer(MemberName))
            {
                List<MonitoredDevice> monitoredDevices = new List<MonitoredDevice>();

                try
                {
                    MonitoredDevicesSection mds = (MonitoredDevicesSection)ConfigurationManager.GetSection("MonitoredDevices");

                    for (int i = 0; i < mds.Items.Count; i++)
                    {
                        MonitoredDevice monitoredDevice = new MonitoredDevice(mds.Items[i].Device, mds.Items[i].PnPDevice, mds.Items[i].DeviceType);
                        monitoredDevices.Add(monitoredDevice);
                    }
                }
                catch (Exception ex)
                {
                    //Do not throw an exception just log it
                    ConnectionMonitorException cme = new ConnectionMonitorException(
                            "No Monitored Devices defined in the configuration file! " + MemberName, ex);
                    Logger.Write(cme);
                }

                return monitoredDevices.ToArray();
            }
        }

        /// <summary>
        /// Obtain list of VPN Adapter Descriptions that must be ignored because
        /// they errantly present a NetworkInterfaceType of "Ethernet"
        /// 
        /// Note:  We have included hard-coded exceptions for Cisco and Juniper
        /// because they are well known.  However, we have also "policy-enabled"
        /// this method.  If we find a policy-managed list of exceptions in the 
        /// registry, we will ignore them, as well.
        /// 
        /// HKLM\SOFTWARE\Policies\Microsoft\ConnectionMonitor\VPNExceptionsList
        /// </summary>
        /// <param></param>
        /// <returns>List of Errant VPN Adapter Descriptions.</returns>
        private static string GetVPNExceptionList()
        {
            const string MemberName = "GetVPNExceptionList";

            using (new Tracer(MemberName))
            {
                StringBuilder exceptionList = new StringBuilder();

                try
                {
                    DataSection ds = (DataSection)ConfigurationManager.GetSection("VPNExceptionList");

                    for (int i = 0; i < ds.Items.Count; i++)
                    {
                        if (i > 0)
                        {
                            exceptionList.Append(",");
                        }
                        exceptionList.Append(ds.Items[i].Data);
                    }
                }
                catch (Exception ex)
                {
                    //Do not throw an exception just log it
                    ConnectionMonitorException cme = new ConnectionMonitorException(
                            "No VPN Exceptions defined in the configuration file! " + MemberName, ex);
                    Logger.Write(cme);
                }

                try
                {
                    // See if the VPN Exceptions are being managed by policy
                    string keyName = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Microsoft\\ConnectionMonitor";
                    string valueName = "VPNExceptionsList";
                    string vpnExceptionList = (string)Registry.GetValue(keyName, valueName, string.Empty);

                    if (!String.IsNullOrEmpty(vpnExceptionList))
                    {
                        //Add the policy exceptions
                        if (exceptionList.Length > 0)
                        {
                            exceptionList.Append(",");
                        }
                        exceptionList.Append(vpnExceptionList);
                    }
                }
                catch (ConnectionMonitorException cme)
                {
                    Logger.Write(cme);
                    throw cme;
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                    throw ex;
                }

                return exceptionList.ToString();
            }
        }
        #endregion

        
        #region Constructor
        /// <summary>
        /// Constructor
        /// </summary>
        public ConMonService()
        {
            InitializeComponent();
        }
        #endregion
    }

    /// <summary>
    /// Empty instance class for callback
    /// </summary>
    internal class ConMonServiceEventsWCFServiceCallback : IConMonServiceEventsCallback
    {
        public void OnServiceStarted()
        {
            throw new NotImplementedException();
        }

        public void OnNICEnabled(string nicName)
        {
            throw new NotImplementedException();
        }

        public void OnServiceStopped()
        {
            throw new NotImplementedException();
        }

        public void OnServicePaused()
        {
            throw new NotImplementedException();
        }

        public void OnServiceRestarted()
        {
            throw new NotImplementedException();
        }

        public void OnDependentServicesChecked(string[] dependentServicesStarted)
        {
            throw new NotImplementedException();
        }

        public void OnIPAddressChanged()
        {
            throw new NotImplementedException();
        }

        public void OnNICsFound(string[] nicNames)
        {
            throw new NotImplementedException();
        }

        public void OnServicePowerEvent(PowerBroadcastStatus status)
        {
            throw new NotImplementedException();
        }
    }

}

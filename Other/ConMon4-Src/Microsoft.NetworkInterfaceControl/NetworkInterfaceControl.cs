using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management;
using System.Net;
using System.Net.NetworkInformation;
using System.Reflection;
using Microsoft.Practices.EnterpriseLibrary.Logging;
using System.Text;

namespace Microsoft.NetworkInterfaceControl
{
    /// <summary>
    /// Contains information and operations on a computer's network interface controllers
    /// </summary>
    public interface INetworkInterfaceControl
    {
        /// <summary>
        /// Enables a network interface
        /// </summary>
        /// <returns>
        /// True - A network interface was enabled.
        /// False - A network interface failed to enable.
        /// </returns>
        bool Enable();
        /// <summary>
        /// Disables a network interface
        /// </summary>
        /// <returns>
        /// True - A network interface was disabled.
        /// False - A network interface failed to disable.
        /// </returns>
        bool Disable();
        /// <summary>
        /// Returns true if machine has a hard wired connection; otherwise false.
        /// </summary>
        bool Wired { get; }
    }

    /// <summary>
    /// Contains information and operations on a computer's network interface controllers
    /// </summary>
    public class NetworkInterfaceController : INetworkInterfaceControl
    {
        /// <summary>
        /// Device being monitored as specified in configuration file
        /// </summary>
        private MonitoredDevice[] _monitoredDevices;
        /// <summary>
        /// List of devices to exclude from being monitored
        /// </summary>
        private static string _vpnExceptionList;

        #region Events
        /// <summary>
        /// Fired when a NICE has been enabled
        /// </summary>
        public event OnNICEnabled NICEnabled;
        #endregion

        #region Delegates
        /// <summary>
        /// Fired when a NIC has been enabled
        /// </summary>
        /// <param name="deviceName">Name of device enabled</param>
        public delegate void OnNICEnabled(string deviceName);
        #endregion

        #region Public Methods
        /// <summary>
        /// Returns true if machine has a hard wired connection; otherwise false.
        /// </summary>
        public bool Wired
        {
            get { return IsWired(); }
        }

        /// <summary>
        /// Enables a network interface
        /// </summary>
        /// <returns>
        /// True - A network interface was enabled.
        /// False - A network interface failed to enable.
        /// </returns>
        public bool Enable()
        {
            bool success = false;

            foreach (MonitoredDevice monitoredDevice in this._monitoredDevices)
            {
                success = monitoredDevice.EnableDevice();
                if (success)
                {
                    if (this.NICEnabled != null) this.NICEnabled(monitoredDevice.Name);

                    // Loop through and disable every other device than the one just enabled.
                    foreach (MonitoredDevice disableMonitoredDevice in this._monitoredDevices)
                    {
                        if (disableMonitoredDevice.Name.CompareTo(monitoredDevice.Name) != 0)
                        {
                            disableMonitoredDevice.DisableDevice();
                        }
                    }

                    break;
                }
            }

            return success;
        }

        /// <summary>
        /// Disables a network interface
        /// </summary>
        /// <returns>
        /// True - A network interface was disabled.
        /// False - A network interface failed to disable.
        /// </returns>
        public bool Disable()
        {
            bool success = true;

            foreach (MonitoredDevice monitoredDevice in this._monitoredDevices)
            {
                success = success & monitoredDevice.DisableDevice();
            }

            return success;
        }
        #endregion

        #region Private Methods
        /// <summary>
        /// Logs a message to the application's log file
        /// </summary>
        /// <param name="msg">Message to log</param>
        /// <param name="severity">Severity of the message/error</param>
        private void LogMessage(string msg, TraceEventType severity)
        {
            Logger.Write(msg, "NetworkInterfaceController", 1, 1, severity);
        }

        /// <summary>
        /// Determines if a machine has a wired network connection.
        /// </summary>
        /// <returns>True if wired, otherwise false.</returns>
        private static bool IsWired()
        {
            foreach (NetworkInterface nic in NetworkInterface.GetAllNetworkInterfaces())
            {
                // BEGIN VPN hack: The Cisco & Juniper VPN adapters errantly present as
                // wired Etherenet connections.  If VPN is over wireless and this is not 
                // handled, the underlying wireless connection will be dropped.
                if (nic.NetworkInterfaceType == NetworkInterfaceType.Ethernet)
                {
                    // Ignore if this is a known VPN within our list of exceptions
                    // Note: I am embedding this under the preceding if statement in order to ensure 
                    //       that this will only be processed when the nic is presenting as "Ethernet"
                    if (IsKnownVPNException(nic))
                    {
                        EventLog.WriteEntry("Connection Monitor", "Detected a VPN adapter that has registered itself as a wired ethernet connection.  Ignoring...", EventLogEntryType.Warning);
                        continue;
                    }
                }
                // END VPN hack

                if (nic.NetworkInterfaceType == NetworkInterfaceType.Ethernet &&
                    nic.OperationalStatus == OperationalStatus.Up &&
                    HasIpAddress(nic))
                {
                    return true;
                }
            }

            return false;
        }

        /// <summary>
        /// Determines if the NIC has the description of a known VPN adapter.
        /// </summary>
        /// <param name="nic"></param>
        /// <returns>True if </returns>
        private static bool IsKnownVPNException(NetworkInterface nic)
        {
            return _vpnExceptionList.ToUpper().Contains(nic.Description.Trim().ToUpper()) ? true : false;
        }

        /// <summary>
        /// Determines if a network adapter has been assigned IP addresses.
        /// </summary>
        /// <param name="nic"></param>
        /// <returns></returns>
        private static bool HasIpAddress(NetworkInterface nic)
        {
            return GetIpAddresses(nic) != null ? true : false;
        }

        /// <summary>
        /// Gets a list of the network adapters IP addresses.
        /// </summary>
        /// <param name="nic"></param>
        /// <returns>Returns an arry of IP addresses</returns>
        private static IPAddress[] GetIpAddresses(NetworkInterface nic)
        {
            IPInterfaceProperties ipProps = nic.GetIPProperties();
            UnicastIPAddressInformationCollection uniCollection = ipProps.UnicastAddresses;

            List<IPAddress> ipAddresses = new List<IPAddress>();
            foreach (UnicastIPAddressInformation ipAddress in uniCollection)
            {
                ipAddresses.Add(ipAddress.Address);
            }

            return ipAddresses.ToArray();
        }
        #endregion

        #region Constructors
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="eventLog">Instance of the eventlog to use</param>
        /// <param name="vpnExceptionList">List of devices to exclude from being monitored</param>
        /// <param name="monitoredDevices">List of devices to monitor</param>
        public NetworkInterfaceController(EventLog eventLog, string vpnExceptionList, MonitoredDevice[] monitoredDevices)
        {
            //_eventLog = eventLog;
            _vpnExceptionList = vpnExceptionList;
            _monitoredDevices = monitoredDevices;

            StringBuilder b = new StringBuilder();
            b.Append("Creating NetworkInterfaceController with the following information:\n");
            b.Append("Known VPN Exceptions:\n");
            if (!String.IsNullOrEmpty(vpnExceptionList))
            {
                string[] vpns = vpnExceptionList.Split(',');
                foreach (string item in vpns)
                {
                    b.Append(String.Format("\t{0}", item));
                }
            }
        }
        #endregion
    }
}

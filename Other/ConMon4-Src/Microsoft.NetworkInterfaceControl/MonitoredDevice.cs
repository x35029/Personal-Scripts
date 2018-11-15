using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management;
using System.Configuration;
using System.Diagnostics;
using Microsoft.Practices.EnterpriseLibrary.Logging;

namespace Microsoft.NetworkInterfaceControl
{
    /// <summary>
    /// Adapter types available to be monitored
    /// </summary>
    public enum MonitoredDeviceType{
        Wired,
        Wireless,
        Modem,
        MobileBroadband
    }

    /// <summary>
    /// Interface for defining attributes and operations available for monitored devices
    /// </summary>
    public interface IMonitoredDevice
    {
        /// <summary>
        /// Name as seen in the configuration file
        /// </summary>
        string Name { get; set; }
        /// <summary>
        /// PnPDeviceName as seen in the configuration file
        /// </summary>
        string PnPDeviceName { get; set; }
        /// <summary>
        /// Device type as defined in the configuration file
        /// </summary>
        MonitoredDeviceType DeviceType { get; set; }
    }

    /// <summary>
    /// Data for a monitored device
    /// </summary>
    public class MonitoredDevice : IMonitoredDevice
    {
        /// <summary>
        /// Data returned from retrieving PNPSignedDrivers information
        /// </summary>
        public struct PnPSignedDriverOutput
        {
            public string ClassGuid;
            public string Name;
            public string HardwareId;
            public string Status;
        }

        /// <summary>
        /// Data returned from retrieving modem information
        /// </summary>
        public struct ModemInfo
        {
            public string Name;
            public string PNPDeviceID;
            public bool IsEnabled;
        }

        /// <summary>
        /// Name of device
        /// </summary>
        private string _name;
        /// <summary>
        /// PnP Name of device
        /// </summary>
        private string _pnpDeviceName;
        /// <summary>
        /// User defined device type
        /// </summary>
        private MonitoredDeviceType _deviceType;

        /// <summary>
        /// Name of device
        /// </summary>
        public string Name
        {
            get { return this._name; }
            set { this._name = value; }
        }

        /// <summary>
        /// PnP Name of device
        /// </summary>
        public string PnPDeviceName
        {
            get { return this._pnpDeviceName; }
            set { this._pnpDeviceName = value; }
        }

        /// <summary>
        /// User defined device type
        /// </summary>
        public MonitoredDeviceType DeviceType
        {
            get { return this._deviceType; }
            set { this._deviceType = value; }
        }

        /// <summary>
        /// Enables a device specified by data of this instance
        /// </summary>
        /// <returns>
        /// True - Device was enabled successfully.
        /// False - Device failed to enable.
        /// </returns>
        public bool EnableDevice()
        {
            bool success = false;

            Logger.Write(string.Format("Enabling Device [{0}]", this._name));

            if (isDeviceNetworkAdapter())
            {
                success = enableNetworkAdapter();
            }
            else if (isDevicePOTSModem())
            {
                success = enablePOTSModem();
            }
            else
            {
                Logger.Write(string.Format("Enabling Device [{0}] failed because either the device name is incorrect or it is not in WMI objects Win32_NetworkAdapter or Win32_POTSModem.", this._name));
            }

            if (success)
            {
                Logger.Write(string.Format("Device [{0}] enabled", this._name));
            }

            return success;
        }

        /// <summary>
        /// Disables a device specified by data of this instance
        /// </summary>
        /// <returns>
        /// True - Device was disabled successfully.
        /// False - Device failed to disable.
        /// </returns>
        public bool DisableDevice()
        {
            bool success = false;

            Logger.Write(string.Format("Disabling Device [{0}]", this._name));

            if (isDeviceNetworkAdapter())
            {
                success = disableNetworkAdapter();
            }
            else if (isDevicePOTSModem())
            {
                success = disablePOTSModem();
            }
            else
            {
                Logger.Write(string.Format("Disabling Device [{0}] failed because either the device is not plugged in or device name is incorrect or it is not in WMI objects Win32_NetworkAdapter or Win32_POTSModem.", this._name));
            }

            if (success)
            {
                Logger.Write(string.Format("Device [{0}] disabled", this._name));
            }

            return success;
        }

        /// <summary>
        /// Determines whether or not a device can be located using the Win32_NetworkAdapter WMI call
        /// </summary>
        /// <returns>True if device is found. False is device is not found.</returns>
        private bool isDeviceNetworkAdapter()
        {
            bool isNetworkAdapter = false;

            ManagementObjectSearcher searcher = new ManagementObjectSearcher("root\\CIMV2", string.Format("SELECT Name FROM Win32_NetworkAdapter WHERE Name='{0}' AND PhysicalAdapter=true", this._name));
            foreach (ManagementObject queryObj in searcher.Get())
            {
                string foundObjName = queryObj["Name"] == null ? string.Empty : queryObj["Name"].ToString();
                if (foundObjName.CompareTo(this._name) == 0)
                {
                    isNetworkAdapter = true;
                    break;
                }
            }

            return isNetworkAdapter;
        }

        /// <summary>
        /// Determines if device can be found using the Win32_POTSModem WMI call
        /// </summary>
        /// <returns>True if device is found. False is device is not found.</returns>
        private bool isDevicePOTSModem()
        {
            bool isPOTSModem = false;

            ManagementObjectSearcher searcher = new ManagementObjectSearcher("root\\CIMV2", string.Format("SELECT Name FROM Win32_POTSModem WHERE Name='{0}'", this._name));
            foreach (ManagementObject queryObj in searcher.Get())
            {
                string foundObjName = queryObj["Name"] == null ? string.Empty : queryObj["Name"].ToString();
                if (foundObjName.CompareTo(this._name) == 0)
                {
                    isPOTSModem = true;
                    break;
                }
            }

            return isPOTSModem;
        }

        /// <summary>
        /// Enables a network adapter
        /// </summary>
        /// <returns>True if network adpater was enabled</returns>
        private bool enableNetworkAdapter()
        {
            bool success = false;

            ManagementObjectSearcher searcher = new ManagementObjectSearcher("root\\CIMV2", string.Format("SELECT Name, DeviceID FROM Win32_NetworkAdapter WHERE Name='{0}'", this._name));
            foreach (ManagementObject queryObj in searcher.Get())
            {
                string deviceId = queryObj["DeviceID"].ToString();

                ManagementObject mgmtObj = new ManagementObject("root\\CIMV2", "Win32_NetworkAdapter.DeviceId='" + deviceId + "'", null);
                try
                {
                    ManagementBaseObject outParams = mgmtObj.InvokeMethod("Enable", null, null);
                    if (outParams["ReturnValue"].ToString() == "0")
                        success = true;
                }
                catch (ManagementException ex)
                {
                    Logger.Write(string.Format("Error enabling network adapter device [{0}]. {1}", this._name, ex.Message));
                }
            }

            return success;
        }

        /// <summary>
        /// Disable a network adapter
        /// </summary>
        /// <returns>True if network adapter was disabled</returns>
        private bool disableNetworkAdapter()
        {
            bool success = false;

            ManagementObjectSearcher searcher = new ManagementObjectSearcher("root\\CIMV2", string.Format("SELECT Name, DeviceID FROM Win32_NetworkAdapter WHERE Name='{0}'", this._name));
            foreach (ManagementObject queryObj in searcher.Get())
            {
                string deviceId = queryObj["DeviceID"].ToString();

                ManagementObject mgmtObj = new ManagementObject("root\\CIMV2", "Win32_NetworkAdapter.DeviceId='" + deviceId + "'", null);
                try
                {
                    ManagementBaseObject outParams = mgmtObj.InvokeMethod("Disable", null, null);
                    if (outParams["ReturnValue"].ToString() == "0")
                        success = true;
                }
                catch (ManagementException ex)
                {
                    Logger.Write(string.Format("Error disabling network adapter device [{0}]. {1}", this._name, ex.Message));
                }
            }

            return success;
        }

        /// <summary>
        /// Enable a POTSModem device
        /// </summary>
        /// <returns>True is device was enabled</returns>
        private bool enablePOTSModem()
        {
            bool success = false;

            PnPSignedDriverOutput[] pnpSignedDriverOutput = getPnPSignedDriverInfo();
            if (pnpSignedDriverOutput != null && pnpSignedDriverOutput.Length == 1)
            {
                if (pnpSignedDriverOutput[0].Name.ToString() == this._name)
                {
                    runDevConEnableDisableDevice(true, pnpSignedDriverOutput[0].HardwareId);
                    if (IsModemEnabled())
                    {
                        success = true;
                    }
                }
            }
            else
            {
                if (pnpSignedDriverOutput == null)
                {
                    Logger.Write(string.Format("Could not find a Win32_PNPDriverEntity for device [{0}]", this._name));
                }

                if (pnpSignedDriverOutput != null && pnpSignedDriverOutput.Length > 1)
                {
                    Logger.Write(string.Format("Win32_PNPDriverEntity returned more than one device for [{0}].", this._name));
                }
            }


            if (success)
            {
                Logger.Write(string.Format("Enable POTSModem succeeded for [{0}].", this._name));
            }
            else
            {
                Logger.Write(string.Format("Enable POTSModem failed for [{0}].", this._name));
            }
            return success;
        }

        /// <summary>
        /// Disable a POTSModem device
        /// </summary>
        /// <returns>True if device was disabled</returns>
        private bool disablePOTSModem()
        {
            bool success = false;

            PnPSignedDriverOutput[] pnpSignedDriverOutput = getPnPSignedDriverInfo();
            if (pnpSignedDriverOutput != null && pnpSignedDriverOutput.Length == 1)
            {
                if (pnpSignedDriverOutput[0].Name.ToString() == this._pnpDeviceName)
                {
                    runDevConEnableDisableDevice(false, pnpSignedDriverOutput[0].HardwareId);
                    if (!IsModemEnabled())
                    {
                        success = true;
                    }
                }
            }
            else
            {
                if (pnpSignedDriverOutput == null)
                {
                    Logger.Write(string.Format("Could not find a Win32_PNPDriverEntity for device [{0}]", this._pnpDeviceName));
                }

                if (pnpSignedDriverOutput != null && pnpSignedDriverOutput.Length > 1)
                {
                    Logger.Write(string.Format("Win32_PNPDriverEntity returned more than one device for [{0}].", this._pnpDeviceName));
                }
            }

            if (success)
            {
                Logger.Write(string.Format("Disable POTSModem succeeded for [{0}].", this._name));
            }
            else
            {
                Logger.Write(string.Format("Disable POTSModem failed for [{0}].", this._name));
            }

            return success;
        }

        /// <summary>
        /// Retrieves information from Win32_PNPSignedDevice WMI call using PnPDevice name
        /// </summary>
        /// <returns>Data structure containing information</returns>
        private PnPSignedDriverOutput[] getPnPSignedDriverInfo()
        {
            List<PnPSignedDriverOutput> returnValue = new List<PnPSignedDriverOutput>();

            ManagementObjectSearcher searcher = new ManagementObjectSearcher("root\\CIMV2", string.Format("SELECT DeviceName, HardwareID, Status, ClassGuid FROM Win32_PnPSignedDriver WHERE DeviceName='{0}'", this._pnpDeviceName));
            Console.WriteLine("All PNPSignedDrivers Found:");
            foreach (ManagementObject queryObj in searcher.Get())
            {
                string name = "Unknown PNPSignedDriver";
                if (queryObj["DeviceName"] != null) name = queryObj["DeviceName"].ToString();
                string hardwareID = string.Empty;
                if (queryObj["HardwareID"] != null) hardwareID = queryObj["HardwareID"].ToString();
                string status = string.Empty;
                if (queryObj["Status"] != null) status = queryObj["Status"].ToString();
                string classGuid = string.Empty;
                if (queryObj["ClassGuid"] != null) classGuid = queryObj["ClassGuid"].ToString();

                PnPSignedDriverOutput output = new PnPSignedDriverOutput();
                output.Name = name;
                output.HardwareId = hardwareID;
                output.Status = status;
                output.ClassGuid = classGuid;
                returnValue.Add(output);
            }

            return returnValue.ToArray();
        }

        /// <summary>
        /// Determines if a POTSModem device is enabled
        /// </summary>
        /// <returns>True if device is enabled</returns>
        private bool IsModemEnabled()
        {
            bool modemEnabled = false;

            ModemInfo[] modemInfos = wmiGetModemInfo();
            if (modemInfos != null && modemInfos.Length == 1)
            {
                modemEnabled = modemInfos[0].IsEnabled;
            }
            else
            {
                if (modemInfos == null)
                {
                    Logger.Write(string.Format("Could not find a Win32_POTSModem for device [{0}]", this._name));
                }

                if (modemInfos != null && modemInfos.Length > 1)
                {
                    Logger.Write(string.Format("Win32_POTSModem returned more than one device for [{0}].", this._name));
                }
            }

            return modemEnabled;
        }

        /// <summary>
        /// Retrieve information on a device using Win32_POTSModem WMI call
        /// </summary>
        /// <returns>Data structure with device information</returns>
        private ModemInfo[] wmiGetModemInfo()
        {
            List<ModemInfo> returnValue = new List<ModemInfo>();

            ManagementObjectSearcher searcher = new ManagementObjectSearcher("root\\CIMV2", string.Format("SELECT Name, StatusInfo, PNPDeviceID FROM Win32_POTSModem WHERE Name='{0}'", this._name));
            foreach (ManagementObject queryObj in searcher.Get())
            {
                string name = queryObj["Name"] == null ? string.Empty : queryObj["Name"].ToString();
                // 2 - Unknown
                // 3 - Enabled
                // 4 - Disabled
                string statusInfo = queryObj["StatusInfo"] == null ? string.Empty : queryObj["StatusInfo"].ToString();
                string pnpDeviceID = queryObj["PNPDeviceID"] == null ? string.Empty : queryObj["StatusInfo"].ToString();

                ModemInfo modemInfo = new ModemInfo();
                modemInfo.Name = name;
                modemInfo.IsEnabled = statusInfo == "3" ? true : false;
                modemInfo.PNPDeviceID = pnpDeviceID;
                returnValue.Add(modemInfo);
            }

            return returnValue.ToArray();
        }

        /// <summary>
        /// Executes enable/disable operations on a device using DevCon.exe command line utility
        /// </summary>
        /// <param name="enableDevice">True to enable a device, false to disable it</param>
        /// <param name="hardwareID">Identifier used by DevCon to perform operations on a particular device</param>
        /// <returns>True if DevCon operation succeeded</returns>
        /// <remarks>Just because this method returns true does not mean the enable/disable operation succeeded. A subsequent call to check the device's status is neccessary.</remarks>
        private bool runDevConEnableDisableDevice(bool enableDevice, string hardwareID)
        {
            bool success = false;
            string devConLocation = null;
            Process devCon = null;
            string enableDisable = null;

            if (ConfigurationManager.AppSettings["DevConLocation"] != null && 
                !string.IsNullOrEmpty(ConfigurationManager.AppSettings["DevConLocation"]) && 
                System.IO.File.Exists(ConfigurationManager.AppSettings["DevConLocation"]))
            {
                devConLocation = ConfigurationManager.AppSettings["DevConLocation"];
            }
            else
            {
                Logger.Write("appSettings must have a key named ConMonLocation that contains a value where the DevCon.exe file can be found.");
            }

            if (!string.IsNullOrEmpty(devConLocation))
            {
                if (enableDevice)
                {
                    enableDisable = "enable";
                }
                else
                {
                    enableDisable = "disable";
                }

                try
                {
                    devCon = new Process();
                    devCon.StartInfo.FileName = devConLocation;
                    devCon.StartInfo.Arguments = string.Format("{0} \"{1}\"", enableDisable, hardwareID);
                    devCon.StartInfo.UseShellExecute = true;
                    devCon.StartInfo.CreateNoWindow = true;
                    devCon.StartInfo.Verb = "runas";
                    success = devCon.Start();
                    devCon.WaitForExit();
                    
                    Logger.Write(string.Format("DevCon.exe succeeded for [{0}]", this._name));
                    success = true;
                }
                catch (Exception ex)
                {
                    Logger.Write(string.Format("DevCon.exe failed for [{0}]. {1}", this._name, ex.Message), EventLogEntryType.Error.ToString());
                }
                finally
                {
                    if (devCon != null)
                    {
                        devCon.Dispose();
                        devCon = null;
                    }
                }
            }

            return success;
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="name">Device name</param>
        /// <param name="pnpDeviceName">PnP Device name</param>
        /// <param name="deviceType">User-defined Device type</param>
        public MonitoredDevice(string name, string pnpDeviceName, MonitoredDeviceType deviceType)
        {
            this._name = name;
            this._pnpDeviceName = pnpDeviceName;
            this._deviceType = deviceType;
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="name">Device name</param>
        /// <param name="pnpDeviceName">PnP Device name</param>
        /// <param name="deviceType">User-defined Device type</param>
        public MonitoredDevice(string name, string pnpDeviceName, string deviceType)
        {
            this._name = name;
            this._pnpDeviceName = pnpDeviceName;

            if (deviceType == "Wired")
            {
                this._deviceType = MonitoredDeviceType.Wired;
            }
            else if (deviceType == "Wireless")
            {
                this._deviceType = MonitoredDeviceType.Wireless;
            }
            else if (deviceType == "Modem")
            {
                this._deviceType = MonitoredDeviceType.Modem;
            }
            else if (deviceType == "MobileBroadband")
            {
                this._deviceType = MonitoredDeviceType.MobileBroadband;
            }
            else
            {
                throw new Exception(string.Format("deviceType [{0}] passed to constructor is not supported.", deviceType));
            }
        }
    }
}

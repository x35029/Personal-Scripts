using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration;
using System.Configuration.Install;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Net.NetworkInformation;
using System.Reflection;
using System.ServiceProcess;
using System.Text;
using System.Xml;
using Microsoft.Win32;
using ConnectionMonitor.Configuration;

namespace ConnectionMonitor.Service
{
    [RunInstaller(true)]
    public partial class ConMonInstaller : Installer
    {
        InstallerLogger _logger;
        public ConMonInstaller()
        {
            InitializeComponent();
        }

        public override void Install(IDictionary stateSaver)
        {
            base.Install(stateSaver);
            
            StartWlanService();

            UpdateAppConfigFile();

            Start();
        }

        private static void StartWlanService()
        {
            ServiceHelper.StartService("wlansvc", "WLAN AutoConfig");
        }

        private void Start()
        {
            ServiceController sc = new ServiceController("ConMon");
            if (sc != null && (sc.Status != ServiceControllerStatus.Running || sc.Status == ServiceControllerStatus.StartPending))
                sc.Start();
        }

        internal void UpdateAppConfigFile()
        {
            Assembly asm = Assembly.GetExecutingAssembly();
            FileInfo configFile = new FileInfo(asm.Location + ".config");

            if (!configFile.Exists)
                throw new InstallException("Could not find the configuration file.");

            updateDevConAppSetting(configFile.FullName, configFile.DirectoryName);
            updateMonitoredDevicesConfigurationSection(configFile.FullName);
        }

        private bool updateMonitoredDevicesConfigurationSection(string configFilename)
        {
            bool success = false;

            try
            {
                TryEnableWireless();

                List<string> wirelessAdapters = GetWirelessAdapterList();
                if (wirelessAdapters == null) throw new InstallException("Connection Monitor could not find any wireless adapters to manage.");

                bool saveMonitoredDevicesSection = false;

                MonitoredDevicesSection mds = MonitoredDevicesSection.LoadConfiguration(configFilename);
                if (mds == null) throw new InstallException("MonitoredDevices section not found.");

                List<string> monitoredDevices = mds.Items.GetAllMonitoredDeviceNames();
                if (monitoredDevices == null) throw new InstallException("Error occured getting all monitored devices.");

                foreach (string wirelessAdapter in wirelessAdapters)
                {
                    if (!monitoredDevices.Contains(wirelessAdapter))
                    {
                        MonitoredDeviceElement wirelessDeviceElement = new MonitoredDeviceElement();
                        wirelessDeviceElement.Device = wirelessAdapter;
                        wirelessDeviceElement.PnPDevice = wirelessAdapter;
                        wirelessDeviceElement.DeviceType = "Wireless";

                        mds.Items.AddAt(mds.Items.StartingIndexForAddingWirelessMonitoredDevices(), wirelessDeviceElement);
                        saveMonitoredDevicesSection = true;
                    }
                }
                
                if (saveMonitoredDevicesSection)
                {
                    if (!MonitoredDevicesSection.SaveConfiguration(configFilename, mds))
                    {
                        throw new InstallException("Failed to save configuration file.");
                    }
                }

                success = true;
            }
            catch (Exception ex)
            {
                throw new InstallException("Failed to update MonitoredDevices section of the configuration file.", ex);
            }

            return success;
        }

        private bool updateDevConAppSetting(string configFilename, string directoryName)
        {
            bool success = false;

            try
            {
                XmlDocument configXml = new XmlDocument();
                configXml.Load(configFilename);

                bool bFoundIt = false;
                foreach (XmlNode node in configXml["configuration"]["appSettings"])
                {
                    if (node.Name == "add" && node.Attributes.GetNamedItem("key").Value == "DevConLocation")
                    {
                        node.Attributes.GetNamedItem("value").Value = string.Format("{0}\\devcon.exe", directoryName);
                        bFoundIt = true;
                        break;
                    }
                }

                if (!bFoundIt)
                    throw new InstallException("Could not find DevCon location section in configuration file");

                configXml.Save(configFilename);

                success = true;
            }
            catch (Exception ex)
            {
                throw new InstallException("Failed to update DevConLocation appSetting.", ex);
            }

            return success;
        }

        /// <summary>
        /// This method tries to enable any wireless adapters.
        /// </summary>
        private void TryEnableWireless()
        {
            // This query tries to find disabled adapters.  It also tries to filter our Bluetooth devices.
            ManagementObjectSearcher searcher =
                new ManagementObjectSearcher("root\\CIMV2",
                "SELECT DeviceID FROM Win32_NetworkAdapter WHERE NetEnabled='False'");

            foreach (ManagementObject queryObj in searcher.Get())
            {
                string deviceID = queryObj["DeviceID"].ToString();
                EnabledAdapter(deviceID);
            }
        }


        /// <summary>
        /// Enables adapters via Win32_NetworkAdapter.Enable using the deviceId
        /// </summary>
        /// <param name="deviceId"></param>
        /// <returns></returns>
        private static bool EnabledAdapter(string deviceId)
        {
            bool bRetVal = false;
            ManagementObject classInstance =
                new ManagementObject("root\\CIMV2",
                "Win32_NetworkAdapter.DeviceID='" + deviceId + "'",
                null);

            // Execute the method and obtain the return values.
            ManagementBaseObject outParams =
                classInstance.InvokeMethod("Enable", null, null);

            // List outParams
            if (outParams["ReturnValue"].ToString() == "0")
                bRetVal = true;

            return bRetVal;
        }

        public override void Uninstall(IDictionary savedState)
        {
            Stop();
            base.Uninstall(savedState);
        }

        private void Stop()
        {
            ServiceController sc = new ServiceController("ConMon");
            if (sc != null && (sc.Status != ServiceControllerStatus.Stopped || sc.Status == ServiceControllerStatus.StopPending))
                sc.Stop();
        }

        private List<string> GetWirelessAdapterList()
        {
            NetworkInterface[] nics = NetworkInterface.GetAllNetworkInterfaces();
            List<NetworkInterface> wirelessNics = new List<NetworkInterface>();
            foreach (NetworkInterface nic in nics)
            {
                if (nic.NetworkInterfaceType == NetworkInterfaceType.Wireless80211)
                    wirelessNics.Add(nic);
            }

            if (wirelessNics.Count == 0)
                return null;

            StringBuilder sb = new StringBuilder();
            List<string> nicNames = new List<string>();
            foreach (NetworkInterface nic in wirelessNics)
            {
                nicNames.Add(nic.Description);
            }

            return nicNames;
        }
    }
}
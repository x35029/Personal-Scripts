using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management;

namespace ConMon.Admin
{
    /// <summary>
    /// Data to be added to MonitoredDeviesListBox and AvailableDevicesListBox
    /// </summary>
    internal class Device : System.Windows.Controls.ListBoxItem
    {
        /// <summary>
        /// Name of the device
        /// </summary>
        private string deviceName;
        /// <summary>
        /// Type of the device
        /// </summary>
        private string deviceType;
        /// <summary>
        /// String populated from WMI call
        /// </summary>
        private string pnpDeviceName;
        /// <summary>
        /// Flag to indicate whether changes have been made since instancing
        /// </summary>
        private bool hasChanged;

        /// <summary>
        /// Gets/Sets Name of the device
        /// </summary>
        public string DeviceName
        {
            get { return this.deviceName; }
            set 
            {
                if (string.Compare(this.deviceName, value) != 0)
                {
                    this.deviceName = value;
                    this.hasChanged = true;
                    base.Content = this.deviceName;
                    base.ToolTip = this.buildToolTip();
                }
            }
        }

        /// <summary>
        /// Gets/Sets Type of the device
        /// </summary>
        public string DeviceType
        {
            get { return this.deviceType; }
            set
            {
                if (string.Compare(this.deviceType, value) != 0)
                {
                    this.deviceType = value;
                    this.hasChanged = true;
                    base.ToolTip = this.buildToolTip();
                }
            }
        }

        public string PnPDeviceName
        {
            get { return this.pnpDeviceName; }
            set
            {
                if (string.Compare(this.pnpDeviceName, value) != 0)
                {
                    this.pnpDeviceName = value;
                    this.hasChanged = true;
                }
            }
        }

        /// <summary>
        /// Gets whether this instance has been modified since the instance was created
        /// </summary>
        public bool HasChanges { get { return this.hasChanged; } }

        /// <summary>
        /// Retrieves a list of device instances that are available to be monitored on the computer
        /// </summary>
        /// <returns></returns>
        public static List<Device> getAvailableDevices()
        {
            List<Device> availableDeviceList = new List<Device>();

            availableDeviceList.AddRange(Device.getWin32NetworkAdapterDeviceList());
            availableDeviceList.AddRange(Device.getWin32POTSModemDeviceList());

            return availableDeviceList;
        }

        /// <summary>
        /// Build the string used for the tooltip
        /// </summary>
        /// <returns>String to be used as the tooltip</returns>
        private string buildToolTip()
        {
            return string.Format("{0}[{1}]", this.deviceName, this.deviceType);
        }

        /// <summary>
        /// Build a list of device instances using Win32_NetworkAdapter WMI call
        /// </summary>
        /// <returns>List of device instances available using Win32_NetworkAdapter WMI call</returns>
        private static List<Device> getWin32NetworkAdapterDeviceList()
        {
            List<Device> networkAdapterDevices = new List<Device>();

            using (ManagementObjectSearcher searcher = new ManagementObjectSearcher("root\\CIMV2", "SELECT Name FROM Win32_NetworkAdapter WHERE PhysicalAdapter=true"))
            {
                foreach (ManagementObject queryObj in searcher.Get())
                {
                    string deviceName = queryObj["Name"] == null ? string.Empty : queryObj["Name"].ToString();

                    Device availableNetworkAdapterDevice = new Device(deviceName, "Wireless", deviceName);

                    networkAdapterDevices.Add(availableNetworkAdapterDevice);
                }
            }

            return networkAdapterDevices;
        }

        /// <summary>
        /// Build a list of device instances using Win32_POTSModem WMI call
        /// </summary>
        /// <returns>List of device instances available using Win32_POTSModem WMI call</returns>
        private static List<Device> getWin32POTSModemDeviceList()
        {
            List<Device> potsModemDevices = new List<Device>();

            using (ManagementObjectSearcher searcher = new ManagementObjectSearcher("root\\CIMV2", "SELECT Name FROM Win32_POTSModem"))
            {
                foreach (ManagementObject queryObj in searcher.Get())
                {
                    string deviceName = queryObj["Name"] == null ? string.Empty : queryObj["Name"].ToString();

                    Device availableNetworkAdapterDevice = new Device(deviceName, "MobileBroadband", deviceName);

                    potsModemDevices.Add(availableNetworkAdapterDevice);
                }
            }

            return potsModemDevices;
        }

        /// <summary>
        /// Constructor
        /// </summary>
        public Device()
            : base()
        {
            this.hasChanged = false;
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="name">Name of the device</param>
        /// <param name="type">Type of the device</param>
        /// <param name="pnpDeviceName">PnP name of the device</param>
        public Device(string name, string type, string pnpDeviceName)
            : this()
        {
            this.deviceName = name;
            this.deviceType = type;
            this.pnpDeviceName = pnpDeviceName;

            base.Content = name;
            base.ToolTip = this.buildToolTip();
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="monitoredDeviceConfigElement">Configuration element to be used to populate data for this instance</param>
        public Device(ConnectionMonitor.Configuration.MonitoredDeviceElement monitoredDeviceConfigElement)
            : this(monitoredDeviceConfigElement.Device, monitoredDeviceConfigElement.DeviceType, monitoredDeviceConfigElement.PnPDevice)
        {
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="device">Instance to copy data from</param>
        public Device(Device device)
            : this(device.deviceName, device.deviceType, device.pnpDeviceName)
        {
        }
    }
}

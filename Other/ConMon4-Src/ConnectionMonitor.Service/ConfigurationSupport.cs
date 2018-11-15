using System;
using System.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace ConnectionMonitor.Configuration
{
#region "Configuration Elements for VPNExceptionList, DependentServiceList"
    public class DataSection : ConfigurationSection
	{
		[ConfigurationProperty("items", IsDefaultCollection = false)]
		[ConfigurationCollection(typeof(DataCollection),
			AddItemName = "add",
			ClearItemsName = "clear",
			RemoveItemName = "remove")]
		public DataCollection Items
		{
			get
			{
				DataCollection itemsCollection =
					(DataCollection)base["items"];
				return itemsCollection;
			}
		}

	}

	public class DataCollection : ConfigurationElementCollection
	{
		public override ConfigurationElementCollectionType  CollectionType
		{
			get
			{
				return ConfigurationElementCollectionType.AddRemoveClearMap;
			}
		}

		public DataElement this[int index]
		{
			get { return (DataElement)BaseGet(index); }
			set
			{
				if (BaseGet(index) != null)
					BaseRemoveAt(index);
				BaseAdd(index, value);
		}
		}

		public void Add(DataElement element)
		{
			BaseAdd(element);
		}

		public void Clear()
		{
			BaseClear();
		}

		protected override ConfigurationElement CreateNewElement()
		{
			return new DataElement();
		}

		protected override object GetElementKey(ConfigurationElement element)
		{
			return ((DataElement)element).Data;
		}

		public void Remove(DataElement element)
		{
			BaseRemove(element.Data);
		}

		public void Remove(string name)
		{
			BaseRemove(name);
		}

		public void RemoveAt(int index)
		{
			BaseRemoveAt(index);
		}
	}

	public class DataElement : ConfigurationElement
	{
		public DataElement() { }

		public DataElement(string data)
		{
			this.Data = data;
		}

        public DataElement(string data, string data2)
        {
            this.Data2 = data2;
        }


		[ConfigurationProperty("Data", IsRequired = true, DefaultValue="")]
		public string Data
		{
			get { return (string)this["Data"]; }
				set { this["Data"] = value; }
		}

        [ConfigurationProperty("Data2", IsRequired = false, DefaultValue = "")]
        public string Data2
        {
            get { return (string)this["Data2"]; }
            set { this["Data2"] = value; }
        }
	}
#endregion

#region "Configuration Elements for MonitoredDevices"
    public class MonitoredDevicesSection : ConfigurationSection
    {
        [ConfigurationProperty("items", IsDefaultCollection = false)]
        [ConfigurationCollection(typeof(MonitoredDevicesCollection),
            AddItemName = "add",
            ClearItemsName = "clear",
            RemoveItemName = "remove")]
        public MonitoredDevicesCollection Items
        {
            get
            {
                MonitoredDevicesCollection itemsCollection =
                    (MonitoredDevicesCollection)base["items"];
                return itemsCollection;
            }
        }

        public static MonitoredDevicesSection LoadConfiguration(string configurationFile)
        {
            MonitoredDevicesSection mds = new MonitoredDevicesSection();

            XmlDocument configXml = new XmlDocument();
            configXml.Load(configurationFile);

            XmlNodeList monitoredDevicesConfigNodes = configXml.DocumentElement.SelectNodes("MonitoredDevices/items/add");
            if (monitoredDevicesConfigNodes != null)
            {
                foreach (XmlNode monitoredDeviceConfigNode in monitoredDevicesConfigNodes)
                {
                    mds.Items.Add(new MonitoredDeviceElement(monitoredDeviceConfigNode));
                }
            }
            else
            {
                throw new Exception("MonitoredDevices section not found.");
            }

            return mds;
        }

        public static bool SaveConfiguration(string configurationFile, MonitoredDevicesSection mdsToSave)
        {
            bool success = false;

            XmlDocument configXml = new XmlDocument();
            configXml.Load(configurationFile);

            XmlNode monitoredDevicesNode = configXml.DocumentElement.SelectSingleNode("MonitoredDevices/items");
            if (monitoredDevicesNode == null) throw new Exception(string.Format("Element MonitoredDevices/items doesn't exist in configuration file ({0}).", configurationFile));

            monitoredDevicesNode.RemoveAll();

            if (mdsToSave != null)
            {
                foreach (MonitoredDeviceElement monitoredDevice in mdsToSave.Items)
                {
                    XmlNode monitoredDeviceNode = monitoredDevice.CreateXmlNode(configXml);

                    monitoredDevicesNode.AppendChild(monitoredDeviceNode);
                }

                configXml.Save(configurationFile);
                success = true;
            }

            return success;
        }
    }

    public class MonitoredDevicesCollection : ConfigurationElementCollection
    {
        public override ConfigurationElementCollectionType CollectionType
        {
            get
            {
                return ConfigurationElementCollectionType.AddRemoveClearMap;
            }
        }

        public MonitoredDeviceElement this[int index]
        {
            get { return (MonitoredDeviceElement)BaseGet(index); }
            set
            {
                if (BaseGet(index) != null)
                    BaseRemoveAt(index);
                BaseAdd(index, value);
            }
        }

        public void Add(MonitoredDeviceElement element)
        {
            BaseAdd(element);
        }

        public void Clear()
        {
            BaseClear();
        }

        protected override ConfigurationElement CreateNewElement()
        {
            return new MonitoredDeviceElement();
        }

        protected override object GetElementKey(ConfigurationElement element)
        {
            return ((MonitoredDeviceElement)element).Device;
        }

        public void Remove(MonitoredDeviceElement element)
        {
            BaseRemove(element.Device);
        }

        public void Remove(string name)
        {
            BaseRemove(name);
        }

        public void RemoveAt(int index)
        {
            BaseRemoveAt(index);
        }

        /// <summary>
        /// Adds an element at the desired index.
        /// </summary>
        /// <param name="index">Index to add element to.</param>
        /// <param name="element">Element to add to list</param>
        public void AddAt(int index, MonitoredDeviceElement element)
        {
            BaseAdd(index, element);
        }

        /// <summary>
        /// Gets all monitored devices int he configuration fiel and returns a list of all the names
        /// </summary>
        /// <returns>Names for all monitored devices in the configuration file</returns>
        public List<string> GetAllMonitoredDeviceNames()
        {
            List<string> monitoredDeviceNames = new List<string>();

            foreach (MonitoredDeviceElement monitoredDevice in this)
            {
                monitoredDeviceNames.Add(monitoredDevice.Device);
            }

            return monitoredDeviceNames;
        }

        /// <summary>
        /// Find the index where wireless devices can start to be added in the configuration file.
        /// </summary>
        /// <remarks>
        /// This method will assume that is no wireless types are found in the configuration, that wireless is at the top of the list.
        /// If this is not a desired, place an empty wireless type into the configuration file.
        /// </remarks>
        /// <returns>Starting index to start adding devices</returns>
        public int StartingIndexForAddingWirelessMonitoredDevices()
        {
            int index = -1;
            bool wirelessSectionFound = false;

            // Loop through all monitored devices until a device of type "Wireless" is found then exit when either the type
            //changes or the end of the list is reached.
            foreach (MonitoredDeviceElement monitoredDevice in this)
            {
                index++;
                if (monitoredDevice.DeviceType == "Wireless")
                {
                    wirelessSectionFound = true;
                }
                else if (wirelessSectionFound)
                {
                    break;
                }
            }

            // If no devices are being monitored or no wireless devices were found, then return 0
            if (index == -1 || !wirelessSectionFound)
            {
                index = 0;
            }

            return index;
        }
    }

    /// <summary>
    /// Devices that are monitored by the application
    /// </summary>
    public class MonitoredDeviceElement : ConfigurationElement
    {
        public MonitoredDeviceElement() { }

        public MonitoredDeviceElement(XmlNode configurationElement)
        {
            if (configurationElement == null) throw new Exception("XmlNode is null.");
            if (configurationElement != null)
            {
                if (configurationElement.Attributes["Device"] == null) throw new Exception("Device atribute is missing.");
                if (configurationElement.Attributes["PnPDevice"] == null) throw new Exception("PnPDevice atribute is missing.");
                if (configurationElement.Attributes["Type"] == null) throw new Exception("Type atribute is missing.");
            }

            this.Device = configurationElement.Attributes["Device"].Value;
            this.PnPDevice = configurationElement.Attributes["PnPDevice"].Value;
            this.DeviceType = configurationElement.Attributes["Type"].Value;
        }

        /// <summary>
        /// Creates an XmlNode instance given a configuration document and populates it with the instance's data
        /// </summary>
        /// <param name="configurationDocument">Document to append XmlNode to.</param>
        /// <returns>Populated XmlNode</returns>
        public XmlNode CreateXmlNode(XmlDocument configurationDocument)
        {
            XmlNode node = configurationDocument.CreateNode(XmlNodeType.Element, "add", null);
            XmlAttribute deviceAttribute = configurationDocument.CreateAttribute("Device");
            XmlAttribute pnpDeviceAttribute = configurationDocument.CreateAttribute("PnPDevice");
            XmlAttribute deviceTypeAttribute = configurationDocument.CreateAttribute("Type");

            deviceAttribute.Value = this.Device;
            pnpDeviceAttribute.Value = this.PnPDevice;
            deviceTypeAttribute.Value = this.DeviceType;

            node.Attributes.Append(deviceAttribute);
            node.Attributes.Append(pnpDeviceAttribute);
            node.Attributes.Append(deviceTypeAttribute);

            return node;
        }

        [ConfigurationProperty("Device", IsRequired = true, DefaultValue = "")]
        public string Device
        {
            get { return (string)this["Device"]; }
            set { this["Device"] = value; }
        }

        [ConfigurationProperty("PnPDevice", IsRequired = true, DefaultValue = "")]
        public string PnPDevice
        {
            get { return (string)this["PnPDevice"]; }
            set { this["PnPDevice"] = value; }
        }

        [ConfigurationProperty("Type", IsRequired = true, DefaultValue = "")]
        public string DeviceType
        {
            get { return (string)this["Type"]; }
            set { this["Type"] = value; }
        }
    }
#endregion
}



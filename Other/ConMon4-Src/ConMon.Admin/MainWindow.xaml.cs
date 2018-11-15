using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Xml;
using System.IO;
using System.Configuration;
using System.ServiceProcess;
using System.Reflection;
using ConnectionMonitor.Configuration;
using System.Threading;

namespace ConMon.Admin
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        #region Private Member Variables
        /// <summary>
        /// Flag to indicate whether the application has changes to save. True is changes need to be saved
        /// </summary>
        private bool hasChanges = false;
        /// <summary>
        /// Thread used to monitor ConnectionMonitor Service status
        /// </summary>
        private Thread connectionMonitorServicestatusMonitoringThread = null;
        /// <summary>
        /// Flag used to indicate to function monitoring ConnectionMonitor Service's status to end
        /// </summary>
        private static bool endConnectionMonitorServicestatusMonitoringThread = false;
        #endregion

        #region Private Delegates
        /// <summary>
        /// Used to raise the MonitoredDeviceCategoryChanged event to notify that a monitored device had it's category modified.
        /// </summary>
        /// <param name="originalDevice">Original Device instance.</param>
        /// <param name="changedDevice">Modified Device instance returned from MonitoredDeviceCategory window.</param>
        private delegate void OnMonitoredDeviceCategegoryChanged(Device originalDevice, Device changedDevice);
        #endregion

        #region Private Events
        /// <summary>
        /// Fired when changes have been made that need to be saved back to Connection Monitor Service configuration file.
        /// </summary>
        private event EventHandler ChangesMade;
        /// <summary>
        /// Device Types ordering has been changed.
        /// </summary>
        private event EventHandler DeviceTypeOrderChanged;
        /// <summary>
        /// Fired when the user changes a monitored device's category
        /// </summary>
        private event OnMonitoredDeviceCategegoryChanged MonitoredDeviceCategegoryChanged;
        #endregion

        public MainWindow()
        {
            InitializeComponent();
        }

        #region Window Event Handlers
        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                this.updateConMonAdminConfigurationFile();

                this.loadAllControls();

                this.ChangesMade += new EventHandler(MainWindow_ChangesMade);
                this.DeviceTypeOrderChanged += new EventHandler(MainWindow_DeviceTypeOrderChanged);
                this.MonitoredDeviceCategegoryChanged += new OnMonitoredDeviceCategegoryChanged(MainWindow_MonitoredDeviceCategegoryChanged);

                this.connectionMonitorServicestatusMonitoringThread = new Thread(new ParameterizedThreadStart(MainWindow.monitorConnectionMonitorServiceStatus));
                this.connectionMonitorServicestatusMonitoringThread.Start(this);
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        /// <summary>
        /// Monitors (in a seperate thread) the ConnectionMonitor Service's status
        /// </summary>
        private static void monitorConnectionMonitorServiceStatus(object mainWindowInstance)
        {
            try
            {
                while (!endConnectionMonitorServicestatusMonitoringThread)
                {
                    MainWindow mainWindow = mainWindowInstance as MainWindow;
                    mainWindow.Dispatcher.Invoke(System.Windows.Threading.DispatcherPriority.Normal, new Action(mainWindow.initializeStartStopConMonServiceControls));

                    Thread.Sleep(300);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(string.Format("Exception occured in monitorConnectionMonitorServiceStatus: {0}", ex.ToString()));
            }
        }

        /// <summary>
        /// Fires when a monitored device's category has changed
        /// </summary>
        /// <param name="originalDevice">Original Device instance.</param>
        /// <param name="changedDevice">Modified Device instance returned from MonitoredDeviceCategory window.</param>
        private void MainWindow_MonitoredDeviceCategegoryChanged(Device originalDevice, Device changedDevice)
        {
            if (originalDevice != null && changedDevice != null)
            {
                this.clearMonitoredDeviceListBox();
                List<Device> devices = this.getMonitoredDeviceList(changedDevice);
                MonitoredDevicesListBox.ItemsSource = devices;
            }            
        }

        /// <summary>
        /// Fires when the device types ordering has changed
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void MainWindow_DeviceTypeOrderChanged(object sender, EventArgs e)
        {
            this.reOrderMonitoredDevicesByType();
        }

        /// <summary>
        /// Fires when the application raises the ChangesMade event
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void MainWindow_ChangesMade(object sender, EventArgs e)
        {
            this.hasChanges =
            this.SaveButton.IsEnabled = true;
        }

        private void SaveButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                if (this.saveChanges())
                {
                    MessageBox.Show("Changes saved.");
                    // Reset changes
                    this.hasChanges =
                        this.SaveButton.IsEnabled = false;
                }
                else
                {
                    MessageBox.Show("saving failed.");
                }
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                if (this.hasChanges)
                {
                    if (MessageBox.Show("Do you want to save your changes?", "Changes Detected", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
                    {
                        this.saveChanges();
                    }
                }

                this.exitApplication();
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            MainWindow.endConnectionMonitorServicestatusMonitoringThread = true;
            this.connectionMonitorServicestatusMonitoringThread.Join(300);
            this.connectionMonitorServicestatusMonitoringThread = null;
        }
        #endregion

        #region Control Events
        #region LogReader Events
        private void LogEntriesRefreshButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;
                this.loadLogReaderControl();
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }
        #endregion

        #region Start/Stop Service Events
        private void ConMonStartStopServiceButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                if (this.isConMonServiceRunning)
                {
                    this.stopConMonService();
                }
                else
                {
                    this.startConMonService();
                }

                this.initializeStartStopConMonServiceControls();
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }
        #endregion

        #region DeviceCategoryPriority Events
        private void DeviceTypeOrderListBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                this.DeviceTypeOrderUpButton.IsEnabled =
                    this.DeviceTypeOrderDownButton.IsEnabled = false;

                if (DeviceTypeOrderListBox.SelectedIndex == DeviceTypeOrderListBox.Items.Count - 1)
                {
                    this.DeviceTypeOrderUpButton.IsEnabled = true;
                }
                else if (DeviceTypeOrderListBox.SelectedIndex == 0)
                {
                    this.DeviceTypeOrderDownButton.IsEnabled = true;
                }
                else if (DeviceTypeOrderListBox.SelectedIndex != -1)
                {
                    this.DeviceTypeOrderUpButton.IsEnabled =
                        this.DeviceTypeOrderDownButton.IsEnabled = true;
                }
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        private void DeviceTypeOrderUpButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                string itemToMove = DeviceTypeOrderListBox.SelectedItem as string;
                int selectedItemIndex = DeviceTypeOrderListBox.SelectedIndex;
                this.moveDeviceTypeOrder(selectedItemIndex, --selectedItemIndex, itemToMove);
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        private void DeviceTypeOrderDownButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                string itemToMove = DeviceTypeOrderListBox.SelectedItem as string;
                int selectedItemIndex = DeviceTypeOrderListBox.SelectedIndex;
                this.moveDeviceTypeOrder(selectedItemIndex, ++selectedItemIndex, itemToMove);
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }
        #endregion

        #region Monitored Devices Events
        private void MonitoredDevicesListBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                this.UnmonitorDeviceButton.IsEnabled = false;

                if (this.MonitoredDevicesListBox.SelectedItem != null)
                {
                    this.UnmonitorDeviceButton.IsEnabled = true;
                }
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        /// <summary>
        /// Fires when an item in the MonitoredDevicesListBox is double-clicked
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void monitoredDeviceItem_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                Device selectedMonitoredDevice = sender as Device;
                Device changedMonitoredDevice = null;

                this.Cursor = Cursors.Wait;

                changedMonitoredDevice = this.selectDeviceCategory(selectedMonitoredDevice);

                if (selectedMonitoredDevice != null && changedMonitoredDevice != null && changedMonitoredDevice.HasChanges)
                {
                    this.MonitoredDeviceCategegoryChanged(selectedMonitoredDevice, changedMonitoredDevice);
                    this.ChangesMade(this, new EventArgs());
                }
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        private void UnmonitorDeviceButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                Device monitoredDevice = this.MonitoredDevicesListBox.SelectedItem as Device;

                if (monitoredDevice != null)
                {
                    // Remove monitored device from MonitoredDevicesListBox
                    List<Device> monitoredDeviceList = this.MonitoredDevicesListBox.ItemsSource as List<Device>;
                    this.clearMonitoredDeviceListBox();
                    monitoredDeviceList.Remove(monitoredDevice);
                    this.MonitoredDevicesListBox.ItemsSource = monitoredDeviceList;

                    // Rebuild AvailableDevicesListBox
                    this.loadAvailableDevices();

                    // Find Device instance for the monitoredDevice removed from MonitoredDevicesListBox in AvailableDevicesListBox
                    Device newAvailableDevice = null;
                    foreach (Device availableDevice in AvailableDevicesListBox.Items)
                    {
                        if (string.Compare(availableDevice.DeviceName, monitoredDevice.DeviceName) == 0)
                        {
                            newAvailableDevice = availableDevice;
                            break;
                        }
                    }

                    // Set SelectedIndex of AvailableDevicesListBox to index located
                    if (newAvailableDevice != null)
                    {
                        this.AvailableDevicesListBox.SelectedItem = newAvailableDevice;
                    }

                    // Set focus on the AvailableDeviesListBox control
                    this.AvailableDevicesListBox.Focus();
                }

                this.ChangesMade(this, new EventArgs());
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }
        #endregion

        #region Available Devices Events
        private void AvailableDevicesListBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                this.MonitorDeviceButton.IsEnabled = false;

                if (this.AvailableDevicesListBox.SelectedItem != null)
                {
                    this.MonitorDeviceButton.IsEnabled = true;
                }
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        private void MonitorDeviceButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                Device availableDevice = this.AvailableDevicesListBox.SelectedItem as Device;

                if( availableDevice != null )
                {
                    // Force user to select a category
                    Device changedAvailableDevice = null;
                    while (changedAvailableDevice == null)
                    {
                        changedAvailableDevice = this.selectDeviceCategory(availableDevice);
                        if (changedAvailableDevice == null)
                        {
                            MessageBox.Show("You must select a device type and click the OK button.");
                        }
                    }

                    // Add selected available device from AvailableDevicesListBox control to MonitoredDeviesListBox
                    this.addAvailableDeviceToMonitoredDeviceListBox(changedAvailableDevice);

                    // Rebuild AvailableDevicesListBox control
                    this.loadAvailableDevices();

                    // Select the newly monitored device item in MonitoredDevicesListBox control
                    Device newlyMonitoredDeviceItem = null;
                    foreach (Device monitoredDevice in this.MonitoredDevicesListBox.Items)
                    {
                        if (string.Compare(monitoredDevice.DeviceName, availableDevice.DeviceName) == 0)
                        {
                            newlyMonitoredDeviceItem = monitoredDevice;
                        }
                    }
                    if (newlyMonitoredDeviceItem != null)
                    {
                        this.MonitoredDevicesListBox.SelectedItem = newlyMonitoredDeviceItem;
                    }

                    // Set focus to MonitoredDevicesListBox control
                    this.MonitoredDevicesListBox.Focus();
                }

                this.ChangesMade(this, new EventArgs());
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }

        private void AvailableDevicesRefreshButton_Click(object sender, RoutedEventArgs e)
        {
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                this.loadAvailableDevices();
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                this.Cursor = defaultCursor;
            }
        }
        #endregion
        #endregion

        #region Private Methods
        #region LogReader Methods
        /// <summary>
        /// Loads the log reader control with log entries
        /// </summary>
        private void loadLogReaderControl()
        {
            const int maxCharsToDisplayInItemText = 35;
            this.LogEntriesListBox.Items.Clear();
            XmlNodeList logEntries = getLogEntryNodes(this.getLogFileFilename);
            if (logEntries != null)
            {
                for (int x = logEntries.Count - 1; x >= 0; x--)
                {
                    XmlNode logEntryNode = logEntries[x];
                    string message = string.Empty;
                    string timestamp = string.Empty;
                    string itemText = string.Empty;
                    if (logEntryNode.Attributes != null)
                    {
                        message = logEntryNode.Attributes["Message"] == null ? string.Empty : logEntryNode.Attributes["Message"].Value;
                        timestamp = logEntryNode.Attributes["Timestamp"] == null ? string.Empty : logEntryNode.Attributes["Timestamp"].Value;


                        if (string.Compare(message + timestamp, string.Empty) != 0)
                        {
                            itemText = string.Format("{0} - {1}", timestamp, message.Substring(0, message.Length < maxCharsToDisplayInItemText ? message.Length : maxCharsToDisplayInItemText));
                        }
                        else
                        {
                            message = itemText = string.Format("Invalid Log Entry Item. Make sure this line in the config file is an XML node {0}", logEntryNode.InnerText);
                        }
                    }
                    else
                    {
                        message = itemText = string.Format("Invalid Log Entry Item. Make sure this line in the config file is an XML node {0}", logEntryNode.InnerText);
                    }
                    ListBoxItem logEntryItem = new ListBoxItem();
                    logEntryItem.Content = itemText;
                    logEntryItem.ToolTip = message;
                    logEntryItem.Tag = logEntryNode;
                    logEntryItem.MouseDoubleClick += new MouseButtonEventHandler(logEntryItem_MouseDoubleClick);
                    this.LogEntriesListBox.Items.Add(logEntryItem);
                }
            }
        }

        /// <summary>
        /// Occurs when the log entry item is double-clicked
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        void logEntryItem_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            LogEntry logEntryWindow = null;
            Cursor defaultCursor = this.Cursor;

            try
            {
                this.Cursor = Cursors.Wait;

                ListBoxItem selectedItem = this.LogEntriesListBox.SelectedItem as ListBoxItem;
                XmlNode logEntryItem = selectedItem != null ? selectedItem.Tag as XmlNode : null;

                logEntryWindow = new LogEntry();
                logEntryWindow.Owner = this;
                logEntryWindow.LogEntryItem = logEntryItem;
                logEntryWindow.ShowDialog();
                logEntryWindow.Close();
                logEntryWindow = null;
            }
            catch (Exception ex)
            {
                this.Cursor = defaultCursor;
                this.displayErrors(ex);
            }
            finally
            {
                if (logEntryWindow != null)
                {
                    logEntryWindow.Close();
                    logEntryWindow = null;
                }

                this.Cursor = defaultCursor;
            }
        }

        /// <summary>
        /// Retrieves the log entries into an XmlNodeList
        /// </summary>
        /// <param name="filename">Filename of the log file</param>
        /// <returns>XmlNodeList containing the log entries</returns>
        private XmlNodeList getLogEntryNodes(string filename)
        {
            XmlNodeList logEntriesNodes = null;

            XmlDocument doc = new XmlDocument();
            XmlElement documentElement = doc.CreateElement("LogEntries");

            using (FileStream fs = File.Open(filename, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            {
                using (StreamReader sr = new StreamReader(fs))
                {
                    while (!sr.EndOfStream)
                    {
                        string logFileEntry = sr.ReadLine();
                        if (!string.IsNullOrEmpty(logFileEntry))
                        {
                            documentElement.InnerXml += logFileEntry;
                        }
                    }
                }
            }

            logEntriesNodes = documentElement.ChildNodes;

            return logEntriesNodes;
        }

        /// <summary>
        /// Gets the LogFile filename from the configuration setting LogFileLocation
        /// </summary>
        private string getLogFileFilename
        {
            get
            {
                string filename = ConfigurationManager.AppSettings["LogFileLocation"];
                if (!File.Exists(filename))
                {
                    throw new ConMonAdminException(string.Format("Log file not found at [{0}]. Add a valid log file location in the app.config file with the key LogFileLocation.", filename));
                }

                return filename;
            }
        }
        #endregion

        #region Start/Stop Service Methods
        /// <summary>
        /// Initializes the Connection Monitor Service status label and start/stop button with text
        /// </summary>
        private void initializeStartStopConMonServiceControls()
        {
            try
            {
                this.ConMonServiceStatusLabel.Content = this.getconMonServiceStatusLabelText();
                this.ConMonStartStopServiceButton.Content = this.getStartStopConMonServiceButtonText();
            }
            catch (ConMonAdminException)
            {
                this.ConMonServiceStatusLabel.Content = "Unknown Status";
                this.ConMonStartStopServiceButton.Content = "Unknown Status";

                throw;
            }
        }

        /// <summary>
        /// Returns the Connection Monitor Service status label text
        /// </summary>
        /// <returns>Connection Monitor Service status label text</returns>
        private string getconMonServiceStatusLabelText()
        {
            string labelText = "Unknown status";

            if (this.isConMonServiceRunning)
            {
                labelText = "Service is started";
            }
            else
            {
                labelText = "Service is stopped";
            }

            return labelText;
        }

        /// <summary>
        /// Returns the Connection Monitor Service start/stop button with text
        /// </summary>
        /// <returns>Connection Monitor Service start/stop button with text</returns>
        private string getStartStopConMonServiceButtonText()
        {
            string buttonText = "Unknown status";

            if (this.isConMonServiceRunning)
            {
                buttonText = "Stop Service";
            }
            else
            {
                buttonText = "Start Service";
            }

            return buttonText;
        }

        /// <summary>
        /// Starts the Connection Monitor Service
        /// </summary>
        private void startConMonService()
        {
            using (ServiceController conMonServiceController = this.conMonServiceController)
            {
                try
                {
                    conMonServiceController.Start();
                    conMonServiceController.WaitForStatus(ServiceControllerStatus.Running, new TimeSpan(this.serviceStatusChangeWaitTicks));
                }
                catch (InvalidOperationException)
                {
                    throw new ConMonAdminException("Cannot start service. Please start the application by right-clicking the executable and selecting RunAs Administrator.");
                }
            }
        }

        /// <summary>
        /// Stops the Connection Monitor Service
        /// </summary>
        private void stopConMonService()
        {
            using (ServiceController conMonServiceController = this.conMonServiceController)
            {
                if (conMonServiceController.CanStop)
                {
                    try
                    {
                        conMonServiceController.Stop();
                        conMonServiceController.WaitForStatus(ServiceControllerStatus.Stopped, new TimeSpan(this.serviceStatusChangeWaitTicks));
                    }
                    catch (InvalidOperationException)
                    {
                        throw new ConMonAdminException("Cannot stop service. Please start the application by right-clicking the executable and selecting RunAs Administrator.");
                    }
                }
            }
        }

        /// <summary>
        /// Checks to see if the Connection Monitor Service is running
        /// </summary>
        /// <returns>True if Connection Monitor Service is running, otherwise false</returns>
        private bool isConMonServiceRunning
        {
            get
            {
                bool isRunning = false;

                using (ServiceController conMonServiceController = this.conMonServiceController)
                {
                    if (conMonServiceController.Status == ServiceControllerStatus.Running)
                    {
                        isRunning = true;
                    }
                }

                return isRunning;
            }
        }

        /// <summary>
        /// Gets the Connection Monitor Service Controller instance.
        /// </summary>
        private ServiceController conMonServiceController
        {
            get
            {
                string serviceName = this.conMonServiceName;
                if (string.IsNullOrEmpty(serviceName))
                {
                    throw new ConMonAdminException(string.Format("Service [{0}] is not found. Please change the ConMonServiceName in appSettings in the configuration file to the name of the Connection Monitor Service.", this.conMonServiceName));
                }

                ServiceController conMonServiceController = new ServiceController(serviceName);
                
                try
                {
                    if (conMonServiceController.ServiceName != serviceName)
                    {
                        throw new ConMonAdminException(string.Format("Service [{0}] is not found. Please change the ConMonServiceName in appSettings in the configuration file to the name of the Connection Monitor Service.", this.conMonServiceName));
                    }
                }
                catch (InvalidOperationException)
                {
                    throw new ConMonAdminException(string.Format("Service [{0}] is not found. Please change the ConMonServiceName in appSettings in the configuration file to the name of the Connection Monitor Service.", this.conMonServiceName));
                }

                return conMonServiceController;
            }
        }

        /// <summary>
        /// Connection Monitor Service Name from AppSettings in Configuration file.
        /// </summary>
        private string conMonServiceName { get { return ConfigurationManager.AppSettings["ConMonServiceName"]; } }

        /// <summary>
        /// Gets the configuration setting ServiceStatusChangeWaitTicks, if not found defaults to 300000000000
        /// </summary>
        private long serviceStatusChangeWaitTicks
        {
            get
            {
                const long serviceStatusChangeWaitTicksDefault = 300000000000;
                long serviceStatusChangeWaitTicks = serviceStatusChangeWaitTicksDefault;

                string serviceStatusChangeWaitTicksConfigValue = ConfigurationManager.AppSettings["ServiceStatusChangeWaitTicks"];
                if( !string.IsNullOrEmpty(serviceStatusChangeWaitTicksConfigValue))
                {
                    if (!long.TryParse(serviceStatusChangeWaitTicksConfigValue, out serviceStatusChangeWaitTicks))
                    {
                        serviceStatusChangeWaitTicks = serviceStatusChangeWaitTicksDefault;
                    }
                }

                return serviceStatusChangeWaitTicks;
            }
        }
        #endregion

        #region DeviceCategoryPriority Methods
        /// <summary>
        /// Loads to DeviceTypeOrderListBox control with a list of items from the configuration file.
        /// </summary>
        private void loadDeviceTypeOrderListBox()
        {
            DeviceTypeOrderListBox.Items.Clear();
            DeviceTypeOrderListBox.ItemsSource = this.getDeviceOrderListFromConfig();
        }

        /// <summary>
        /// Read DeviceTypes from the DeviceTypeOrderListBox aand return as a List of string instances.
        /// </summary>
        /// <returns>List of DeviceType string</returns>
        private List<string> getDeviceTypesFromListBox()
        {
            List<string> deviceTypes = new List<string>();

            System.Collections.IEnumerable deviceTypesEnumerable = DeviceTypeOrderListBox.ItemsSource;

            foreach (string deviceType in deviceTypesEnumerable)
            {
                deviceTypes.Add(deviceType);
            }

            return deviceTypes;
        }

        /// <summary>
        /// Move a DeviceType from one spot to another as specified by the parameters and keep focus on the item being moved
        /// </summary>
        /// <param name="deviceTypeToMoveIndex">Current index of the item to move</param>
        /// <param name="deviceTypeNewIndex">Index to move the item to</param>
        /// <param name="deviceTypeValue">Item to move</param>
        private void moveDeviceTypeOrder(int deviceTypeToMoveIndex, int deviceTypeNewIndex, string deviceTypeValue)
        {
            List<string> deviceTypes = this.getDeviceTypesFromListBox();
            DeviceTypeOrderListBox.ItemsSource = null;
            deviceTypes.RemoveAt(deviceTypeToMoveIndex);
            deviceTypes.Insert(deviceTypeNewIndex, deviceTypeValue);
            DeviceTypeOrderListBox.ItemsSource = deviceTypes;

            DeviceTypeOrderListBox.SelectedIndex = deviceTypeNewIndex;
            DeviceTypeOrderListBox.Focus();

            this.ChangesMade(this, new EventArgs());
            this.DeviceTypeOrderChanged(this, new EventArgs());
        }

        /// <summary>
        /// Determines whether to return the device types order list from the on-screen listbox or retrieve from the configuration file.
        /// </summary>
        /// <returns>List of device types in order</returns>
        private List<string> getDeviceTypeOrderList()
        {
            List<string> deviceTypeOrderList = new List<string>();

            if (DeviceTypeOrderListBox.ItemsSource != null)
            {
                deviceTypeOrderList = this.getDeviceTypesFromListBox();
            }
            else
            {
                deviceTypeOrderList = this.getDeviceOrderListFromConfig();
            }

            return deviceTypeOrderList;
        }

        /// <summary>
        /// Retrieve the device type ordering list from the configuration file.
        /// </summary>
        /// <returns>List of device types in order as they appear in the configuration file</returns>
        private List<string> getDeviceOrderListFromConfig()
        {
            List<string> deviceTypes = new List<string>();
            MonitoredDevicesSection mds = MonitoredDevicesSection.LoadConfiguration(this.conMonServiceConfigFileLocation);

            foreach (MonitoredDeviceElement monitoredDeviceConfigElement in mds.Items)
            {
                if (!deviceTypes.Contains(monitoredDeviceConfigElement.DeviceType))
                {
                    deviceTypes.Add(monitoredDeviceConfigElement.DeviceType);
                }
            }

            return deviceTypes;
        }

        /// <summary>
        /// Adds a new device type to DeviceTypeOrderListBox
        /// </summary>
        /// <param name="deviceTypeToAdd"></param>
        private void addNewDeviceType(string deviceTypeToAdd)
        {
            List<string> deviceTypes = this.getDeviceTypeOrderList();
            deviceTypes.Add(deviceTypeToAdd);
            this.DeviceTypeOrderListBox.ItemsSource = deviceTypes;
        }
        #endregion

        #region Monitored Devies Methods
        /// <summary>
        /// Loads the MonitoredDevicesListBox with values
        /// </summary>
        private void loadMonitoredDevices()
        {
            this.clearMonitoredDeviceListBox();
            MonitoredDevicesListBox.ItemsSource = this.getMonitoredDeviceList();
        }

        /// <summary>
        /// Retrieves the list of monitored devices from the Connection Monitor Configuration file.
        /// </summary>
        /// <param name="deviceToReplace">OPTIONAL - If an instance of Device is passed, will replace what is read from the configuration with the instance data passed and returns the list. NOTE: this method does not save the configuration file so passing this instance does not write it out to the configuration, this is only reflected in memory, not persisted!</param>
        /// <returns>List of Device instances build from the configuration file</returns>
        private List<Device> getMonitoredDeviceList(Device deviceToReplace = null)
        {
            List<Device> devices = new List<Device>();
            MonitoredDevicesSection mds = MonitoredDevicesSection.LoadConfiguration(this.conMonServiceConfigFileLocation);
            List<string> deviceTypeOrderList = this.getDeviceTypeOrderList();

            foreach (string deviceTypeOrder in deviceTypeOrderList)
            {
                foreach (MonitoredDeviceElement monitoredDeviceConfigElement in mds.Items)
                {
                    if( string.Compare(monitoredDeviceConfigElement.DeviceType, deviceTypeOrder) == 0 ||
                        (deviceToReplace != null && string.Compare(deviceToReplace.DeviceType, deviceTypeOrder) == 0))
                    {
                        Device deviceItem = null;

                        if (deviceToReplace != null && deviceToReplace.DeviceName == monitoredDeviceConfigElement.Device)
                        {
                            deviceItem = deviceToReplace;
                        }
                        else
                        {
                            deviceItem = new Device(monitoredDeviceConfigElement);
                        }
                        deviceItem.MouseDoubleClick += new MouseButtonEventHandler(monitoredDeviceItem_MouseDoubleClick);
                        devices.Add(deviceItem);
                    }
                }
            }

            return devices;
        }

        /// <summary>
        /// Add the availableDevice instance to the MonitoredDeviceListBox
        /// </summary>
        /// <param name="availableDevice">Available device to be monitored</param>
        private void addAvailableDeviceToMonitoredDeviceListBox(Device availableDevice)
        {
            Device availableDeviceToAdd = new Device(availableDevice);
            List<Device> devices = this.MonitoredDevicesListBox.ItemsSource as List<Device>;
            this.clearMonitoredDeviceListBox();
            List<string> deviceTypeOrderList = this.getDeviceTypeOrderList();
            List<Device> newDeviceList = new List<Device>();

            // Add devices in order by category
            foreach (string deviceTypeOrder in deviceTypeOrderList)
            {
                foreach (Device monitoredDevice in devices)
                {
                    if(availableDeviceToAdd != null && string.Compare(availableDeviceToAdd.DeviceType, deviceTypeOrder) == 0)
                    {
                        Device deviceToAdd = new Device(availableDeviceToAdd);
                        deviceToAdd.MouseDoubleClick += new MouseButtonEventHandler(monitoredDeviceItem_MouseDoubleClick);
                        newDeviceList.Add(deviceToAdd);

                        // Null out so device won't be added again
                        availableDeviceToAdd = null;
                    }
                    
                    if (string.Compare(monitoredDevice.DeviceType, deviceTypeOrder) == 0 )
                    {
                        Device deviceItem = new Device(monitoredDevice);
                        deviceItem.MouseDoubleClick += new MouseButtonEventHandler(monitoredDeviceItem_MouseDoubleClick);
                        newDeviceList.Add(deviceItem);
                    }
                }
            }

            // If availableDeviceToAdd is still instanced, then add category to DeviceTypeOrderListBox and add item to list
            if (availableDeviceToAdd != null)
            {
                this.addNewDeviceType(availableDeviceToAdd.DeviceType);
                newDeviceList.Add(availableDeviceToAdd);
            }

            this.MonitoredDevicesListBox.ItemsSource = newDeviceList;
        }

        /// <summary>
        /// Clears the MonitoredDevicesListBox ItemSource property and remove all event handlers for items before doing so.
        /// </summary>
        private void clearMonitoredDeviceListBox()
        {
            foreach (Device monitoredDeviceItem in MonitoredDevicesListBox.Items)
            {
                monitoredDeviceItem.MouseDoubleClick -= this.monitoredDeviceItem_MouseDoubleClick;
            }

            MonitoredDevicesListBox.ItemsSource = null;
        }

        /// <summary>
        /// Reorder the monitored devices as specified in the DeviceTypeOrderListBox
        /// </summary>
        private void reOrderMonitoredDevicesByType()
        {
            this.loadMonitoredDevices();
        }

        /// <summary>
        /// Retrieve a list of device instances that reside in the MonitoredDeviceListBox control
        /// </summary>
        /// <returns>List of device instances</returns>
        private List<Device> getMonitoredDevicesFromMonitoredDeviceListBox()
        {
            List<Device> monitoredDeviceList = new List<Device>();

            foreach (Device monitoredDevice in this.MonitoredDevicesListBox.Items)
            {
                monitoredDeviceList.Add(monitoredDevice);
            }

            return monitoredDeviceList;
        }
        #endregion

        #region Available Devices Methods
        /// <summary>
        /// Loads AvailableDevicesListBox with values
        /// </summary>
        private void loadAvailableDevices()
        {
            this.AvailableDevicesListBox.ItemsSource = null;
            this.AvailableDevicesListBox.ItemsSource = this.getAvailableDeviceList();
        }

        /// <summary>
        /// Retrieves a list of available devices on the machine excluding devices already monitored
        /// </summary>
        /// <returns>List of devices available on the machine excluding devices already beinbg monitored</returns>
        private List<Device> getAvailableDeviceList()
        {
            List<Device> filteredAvailableDeviceList = new List<Device>();
            List<Device> monitoredDeviceList = this.getMonitoredDevicesFromMonitoredDeviceListBox();
            List<Device> availableDeviceList = Device.getAvailableDevices();

            foreach (Device availableDevice in availableDeviceList)
            {
                if (!this.isAvailableDeviceInMonitoredDeviceList(availableDevice, monitoredDeviceList))
                {
                    filteredAvailableDeviceList.Add(availableDevice);
                }
            }

            return filteredAvailableDeviceList;
        }

        /// <summary>
        /// Tries to find availableDevice in the list of devices (monitoredDeviceList)
        /// </summary>
        /// <param name="availableDevice">Device to find in list</param>
        /// <param name="monitoredDeviceList">List of devices top search</param>
        /// <returns></returns>
        private bool isAvailableDeviceInMonitoredDeviceList(Device availableDevice, List<Device> monitoredDeviceList)
        {
            bool isFound = false;

            foreach (Device monitoredDevice in monitoredDeviceList)
            {
                if (string.Compare(availableDevice.DeviceName, monitoredDevice.DeviceName) == 0)
                {
                    isFound = true;
                    break;
                }
            }

            return isFound;
        }
        #endregion

        #region Save Changes Methods
        /// <summary>
        /// Saves changes made in the application by the user back to the Connection Monitor configuration file.
        /// </summary>
        private bool saveChanges()
        {
            bool success = false;
            MonitoredDevicesSection mds = new MonitoredDevicesSection();

            foreach (Device monitoredDevice in this.MonitoredDevicesListBox.Items)
            {
                MonitoredDeviceElement monitoredDeviceElement = new MonitoredDeviceElement();
                monitoredDeviceElement.Device = monitoredDevice.DeviceName;
                monitoredDeviceElement.DeviceType = monitoredDevice.DeviceType;
                monitoredDeviceElement.PnPDevice = monitoredDevice.PnPDeviceName;
                mds.Items.Add(monitoredDeviceElement);
            }

            success = MonitoredDevicesSection.SaveConfiguration(
                this.conMonServiceConfigFileLocation, mds);
            return success;
        }
        #endregion

        #region Common Methods
        /// <summary>
        /// Loads all controls with initial data
        /// </summary>
        private void loadAllControls()
        {
            this.loadLogReaderControl();
            this.initializeStartStopConMonServiceControls();
            this.loadDeviceTypeOrderListBox();
            this.loadMonitoredDevices();
            this.loadAvailableDevices();
        }

        /// <summary>
        /// Exits the application and cleans up anything that needs to be.
        /// </summary>
        private void exitApplication()
        {
            this.Close();
        }

        /// <summary>
        /// Displays errors to the user
        /// </summary>
        /// <param name="ex">Error to display</param>
        private void displayErrors(Exception ex)
        {
            if (ex is ConMonAdminException)
            {
                MessageBox.Show(ex.Message, "ConMonAdminException Error Occured:", MessageBoxButton.OK);
            }
            else
            {
                MessageBox.Show(ex.ToString(), "Error Occured:", MessageBoxButton.OK);
            }
        }

        /// <summary>
        /// Connection Monitor Service Configuration file location
        /// </summary>
        private string conMonServiceConfigFileLocation
        {
            get
            {
                return ConfigurationManager.AppSettings["ConMonServiceConfigFileLocation"];
            }
        }
        
        /// <summary>
        /// Allow user to change a device's devicetype
        /// </summary>
        /// <param name="deviceToSelectCategoryFor">Device to change</param>
        /// <returns>Newly changed device</returns>
        private Device selectDeviceCategory(Device deviceToSelectCategoryFor)
        {
            Device changedDevice = null;

            MonitoredDeviceCategory monitoredDeviceCategoryWindow = null;
            try
            {
                monitoredDeviceCategoryWindow = new MonitoredDeviceCategory();
                monitoredDeviceCategoryWindow.Owner = this;
                monitoredDeviceCategoryWindow.MonitoredDevice = deviceToSelectCategoryFor;
                monitoredDeviceCategoryWindow.ShowDialog();
                if (!monitoredDeviceCategoryWindow.WasCancelled)
                {
                    changedDevice = monitoredDeviceCategoryWindow.MonitoredDevice;
                }
            }
            finally
            {
                monitoredDeviceCategoryWindow.Close();
                monitoredDeviceCategoryWindow = null;
            }

            return changedDevice;
        }

        private bool updateConMonAdminConfigurationFile()
        {
            bool success = false;

            Assembly asm = Assembly.GetExecutingAssembly();
            string configFileName = asm.Location + ".config";
            FileInfo configFile = new FileInfo(configFileName);

            if (!configFile.Exists)
                throw new Exception("Could not find the CMAT configuration file.");

            try
            {
                XmlDocument configXml = new XmlDocument();
                configXml.Load(configFileName);

                bool bFoundIt = false;
                foreach (XmlNode node in configXml["configuration"]["appSettings"])
                {
                    if (node.Name == "add" && node.Attributes.GetNamedItem("key").Value == "ConMonServiceConfigFileLocation")
                    {
                        node.Attributes.GetNamedItem("value").Value = string.Format("{0}\\ConnectionMonitor.Service.exe.config", configFile.DirectoryName);
                        bFoundIt = true;
                        break;
                    }
                }

                if (!bFoundIt)
                    throw new Exception("Could not find Connection Monitor Service Configuration File location section in configuration file");

                configXml.Save(configFileName);

                success = true;
            }
            catch (Exception ex)
            {
                throw new Exception("Failed to update ConMonServiceConfigFileLocation appSetting.", ex);
            }

            return success;
        }
        #endregion
        #endregion
    }
}

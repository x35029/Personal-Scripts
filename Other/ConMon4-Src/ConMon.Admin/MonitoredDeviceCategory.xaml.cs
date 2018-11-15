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
using System.Windows.Shapes;

namespace ConMon.Admin
{
    /// <summary>
    /// Interaction logic for MonitoredDeviceCategory.xaml
    /// </summary>
    public partial class MonitoredDeviceCategory : Window
    {
        private bool wasCancelled = false;
        private Device monitoredDevice = null;

        public MonitoredDeviceCategory()
        {
            InitializeComponent();
        }

        internal Device MonitoredDevice
        {
            get
            {
                return this.monitoredDevice;
            }
            set
            {
                this.monitoredDevice = value;
            }
        }

        internal bool WasCancelled
        {
            get { return this.wasCancelled; }
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            if (this.monitoredDevice == null)
            {
                MessageBox.Show("No monitored device passed to window.");
                this.Close();
            }
            else
            {
                try
                {
                    foreach (ComboBoxItem categoryItem in CategoryComboBox.Items)
                    {
                        if (categoryItem.Content.ToString() == this.monitoredDevice.DeviceType)
                        {
                            CategoryComboBox.SelectedItem = categoryItem;
                            break;
                        }
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.ToString());
                }
            }
        }

        private void CategoryComboBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            this.monitoredDevice.DeviceType = ((ComboBoxItem)this.CategoryComboBox.SelectedItem).Content.ToString();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            this.wasCancelled = true;
        }

        private void OKButton_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
    }
}

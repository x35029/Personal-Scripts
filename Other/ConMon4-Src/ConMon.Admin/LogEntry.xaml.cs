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
using System.Xml;

namespace ConMon.Admin
{
    /// <summary>
    /// Interaction logic for LogEntry.xaml
    /// </summary>
    public partial class LogEntry : Window
    {
        private XmlNode logEntry = null;

        public XmlNode LogEntryItem
        {
            set
            {
                this.logEntry = value;
            }
        }

        public LogEntry()
        {
            InitializeComponent();
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            if (this.logEntry == null)
            {
                MessageBox.Show("No Log entry passed to window.");
                this.Close();
            }

            this.clearControls();
            this.populateControls();
        }

        private void clearControls()
        {
            this.TimestampValueLabel.Content = string.Empty;
            this.MessageValueTextBox.Text = string.Empty;
            this.CategoryValueLabel.Content = string.Empty;
            this.PriorityValueLabel.Content = string.Empty;
            this.EventIdValueLabel.Content = string.Empty;
            this.SeverityValueLabel.Content = string.Empty;
            this.TitleValueLabel.Content = string.Empty;
            this.MachineValueLabel.Content = string.Empty;
            this.AppDomainValueLabel.Content = string.Empty;
            this.ProcessIdValueLabel.Content = string.Empty;
            this.ThreadIdValueLabel.Content = string.Empty;
            this.ThreadNameValueLabel.Content = string.Empty;
        }

        private void populateControls()
        {
            this.TimestampValueLabel.Content = logEntry.Attributes["Timestamp"].Value;
            this.TimestampValueLabel.ToolTip = logEntry.Attributes["Timestamp"].Value;

            this.MessageValueTextBox.Text = logEntry.Attributes["Message"].Value;
            this.MessageValueTextBox.ToolTip = logEntry.Attributes["Message"].Value;
            
            this.CategoryValueLabel.Content = logEntry.Attributes["Category"].Value;
            this.CategoryValueLabel.ToolTip = logEntry.Attributes["Category"].Value;

            this.PriorityValueLabel.Content = logEntry.Attributes["Priority"].Value;
            this.PriorityValueLabel.ToolTip = logEntry.Attributes["Priority"].Value;
            
            this.EventIdValueLabel.Content = logEntry.Attributes["EventId"].Value;
            this.EventIdValueLabel.ToolTip = logEntry.Attributes["EventId"].Value;
            
            this.SeverityValueLabel.Content = logEntry.Attributes["Severity"].Value;
            this.SeverityValueLabel.ToolTip = logEntry.Attributes["Severity"].Value;
            
            this.TitleValueLabel.Content = logEntry.Attributes["Title"].Value;
            this.TitleValueLabel.ToolTip = logEntry.Attributes["Title"].Value;
            
            this.MachineValueLabel.Content = logEntry.Attributes["Machine"].Value;
            this.MachineValueLabel.ToolTip = logEntry.Attributes["Machine"].Value;
            
            this.AppDomainValueLabel.Content = logEntry.Attributes["AppDomain"].Value;
            this.AppDomainValueLabel.ToolTip = logEntry.Attributes["AppDomain"].Value;
            
            this.ProcessIdValueLabel.Content = logEntry.Attributes["ProcessId"].Value;
            this.ProcessIdValueLabel.ToolTip = logEntry.Attributes["ProcessId"].Value;

            this.ThreadIdValueLabel.Content =
            this.ThreadIdValueLabel.ToolTip = logEntry.Attributes["Win32ThreadId"].Value;

            this.ThreadNameValueLabel.Content =
            this.ThreadNameValueLabel.ToolTip = logEntry.Attributes["ProcessName"].Value;
        }

        private void OKButton_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
    }
}

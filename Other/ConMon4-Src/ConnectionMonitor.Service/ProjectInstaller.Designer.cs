namespace ConnectionMonitor.Service
{
    partial class ProjectInstaller
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.serviceProcessInstaller = new System.ServiceProcess.ServiceProcessInstaller();
            this.serviceInstaller = new System.ServiceProcess.ServiceInstaller();
            this.eventLogInstaller = new System.Diagnostics.EventLogInstaller();
            // 
            // serviceProcessInstaller
            // 
            this.serviceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.LocalSystem;
            this.serviceProcessInstaller.Password = null;
            this.serviceProcessInstaller.Username = null;
            // 
            // serviceInstaller
            // 
            this.serviceInstaller.Description = "Connection Monitor prevents dual homing between the wired and wireless adapters. " +
                " Wired adapters take precedence.";
            this.serviceInstaller.DisplayName = "Connection Monitor";
            this.serviceInstaller.ServiceName = "ConMon";
            this.serviceInstaller.ServicesDependedOn = new string[] {
        "NlaSvc",
        "Wlansvc",
        "lmhosts",
        "ConMonServiceEvents"};
            this.serviceInstaller.StartType = System.ServiceProcess.ServiceStartMode.Automatic;
            // 
            // eventLogInstaller
            // 
            this.eventLogInstaller.CategoryCount = 0;
            this.eventLogInstaller.CategoryResourceFile = null;
            this.eventLogInstaller.Log = "Application";
            this.eventLogInstaller.MessageResourceFile = null;
            this.eventLogInstaller.ParameterResourceFile = null;
            this.eventLogInstaller.Source = "ConMon";
            // 
            // ProjectInstaller
            // 
            this.Installers.AddRange(new System.Configuration.Install.Installer[] {
            this.serviceProcessInstaller,
            this.serviceInstaller,
            this.eventLogInstaller});

        }

        #endregion

        private System.ServiceProcess.ServiceProcessInstaller serviceProcessInstaller;
        private System.ServiceProcess.ServiceInstaller serviceInstaller;
        private System.Diagnostics.EventLogInstaller eventLogInstaller;
    }
}
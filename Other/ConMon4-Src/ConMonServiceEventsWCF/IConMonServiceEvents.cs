using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;
using System.ServiceProcess;

namespace ConMonServiceEventsWCF
{
    /// <summary>
    /// Defines Publisher and Subscriber methods
    /// </summary>
    [ServiceContract(CallbackContract = typeof(IConMonServiceEventsCallBack))]
    public interface IConMonServiceEvents
    {
        /// <summary>
        /// Allows a caller to subscribe to events
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void Subscribe();

        /// <summary>
        /// Allows a caller to unsubscribe to events
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void Unsubscribe();

        /// <summary>
        /// Publish that the service started
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void ServiceStarted();

        /// <summary>
        /// Publish that a NIC has been enabled
        /// </summary>
        /// <param name="nicName">Name of the NIC that was enabled</param>
        [OperationContract(IsOneWay = true)]
        void NICEnabled(string nicName);

        /// <summary>
        /// Publish that the service stopped
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void ServiceStopped();

        /// <summary>
        /// Publish that the service was paused
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void ServicePaused();

        /// <summary>
        /// Publish that the service was restarted
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void ServiceRestarted();

        /// <summary>
        /// Publish that the service checked for dependent services and started them
        /// </summary>
        /// <param name="dependentServicesStarted">List of service names started by Connection Monitor</param>
        [OperationContract(IsOneWay = true)]
        void DependentServicesChecked(string[] dependentServicesStarted);

        /// <summary>
        /// Publish that the service detected an IPAddress change
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void IPAddressChanged();

        /// <summary>
        /// Publish that the service found NICs to monitor connections for
        /// </summary>
        /// <param name="nicNames">List of NIC names Connection Monitor will control</param>
        [OperationContract(IsOneWay = true)]
        void NICsFound(string[] nicNames);

        /// <summary>
        /// Publish that the service detected a power event
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void ServicePowerEvent(PowerBroadcastStatus status);
    }

    /// <summary>
    /// Callback interface used to call subscribers when Connection Monitor service publishes an event
    /// </summary>
    [ServiceContract]
    public interface IConMonServiceEventsCallBack
    {
        /// <summary>
        /// Connection Monitor service started
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void OnServiceStarted();

        /// <summary>
        /// Connection Monitor service enabled a NIC
        /// </summary>
        /// <param name="nicName">Name of NIC enabled</param>
        [OperationContract(IsOneWay = true)]
        void OnNICEnabled(string nicName);

        /// <summary>
        /// Connection Monitor service stopped
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void OnServiceStopped();

        /// <summary>
        /// Connection Monitor service paused
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void OnServicePaused();

        /// <summary>
        /// Connection Monitor service restarted
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void OnServiceRestarted();

        /// <summary>
        /// Connection Monitor service checked for dependent services and started them
        /// </summary>
        /// <param name="dependentServicesStarted">List of service names started by Connection Monitor</param>
        [OperationContract(IsOneWay = true)]
        void OnDependentServicesChecked(string[] dependentServicesStarted);

        /// <summary>
        /// Connection Monitor service detected an IPAddress change
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void OnIPAddressChanged();

        /// <summary>
        /// Connection Monitor service found NICs to monitor connections for
        /// </summary>
        /// <param name="nicNames">List of NIC names Connection Monitor will control</param>
        [OperationContract(IsOneWay = true)]
        void OnNICsFound(string[] nicNames);

        /// <summary>
        /// Connection Monitor service detected a power event
        /// </summary>
        [OperationContract(IsOneWay = true)]
        void OnServicePowerEvent(PowerBroadcastStatus status);
    }
}

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
    /// Publisher/Subscription service used to publish and broadcast Connection Monitor service events
    /// </summary>
    [ServiceBehavior()]
    public class ConMonServiceEvents : IConMonServiceEvents
    {
        /// <summary>
        /// List of application that have subscribed to listen to Connection Monitor events
        /// </summary>
        private static List<IConMonServiceEventsCallBack> _subscribers = new List<IConMonServiceEventsCallBack>();

        /// <summary>
        /// Allows a client to subscribe to listen to Connection Monitor service's published events
        /// </summary>
        public void Subscribe()
        {
            IConMonServiceEventsCallBack newSubscriber = OperationContext.Current.GetCallbackChannel<IConMonServiceEventsCallBack>();
            if (!_subscribers.Contains<IConMonServiceEventsCallBack>(newSubscriber))
            {
                _subscribers.Add(newSubscriber);
            }
        }

        /// <summary>
        /// Allows a client to unsubscribe from event notifications
        /// </summary>
        public void Unsubscribe()
        {
            IConMonServiceEventsCallBack subscriber = OperationContext.Current.GetCallbackChannel<IConMonServiceEventsCallBack>();
            if (subscriber != null)
            {
                _subscribers.Remove(subscriber);
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a ServiceStarted event to subscribers
        /// </summary>
        public void ServiceStarted()
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnServiceStarted();
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a NICEnabled event to subscribers
        /// </summary>
        public void NICEnabled(string nicName)
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnNICEnabled(nicName);
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a ServiceStopped event to subscribers
        /// </summary>
        public void ServiceStopped()
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnServiceStopped();
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a ServicePaused event to subscribers
        /// </summary>
        public void ServicePaused()
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnServicePaused();
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a ServiceRestarted event to subscribers
        /// </summary>
        public void ServiceRestarted()
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnServiceRestarted();
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a DependentServicesChecked event to subscribers
        /// </summary>
        public void DependentServicesChecked(string[] dependentServicesStarted)
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnDependentServicesChecked(dependentServicesStarted);
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a IPAddressChanged event to subscribers
        /// </summary>
        public void IPAddressChanged()
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnIPAddressChanged();
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a NICsFound event to subscribers
        /// </summary>
        public void NICsFound(string[] nicNames)
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnNICsFound(nicNames);
            }
        }

        /// <summary>
        /// Allows Connection Monitor service to publish a ServicePowerEvent event to subscribers
        /// </summary>
        public void ServicePowerEvent(PowerBroadcastStatus status)
        {
            foreach (IConMonServiceEventsCallBack subscriber in _subscribers)
            {
                subscriber.OnServicePowerEvent(status);
            }
        }
    }
}

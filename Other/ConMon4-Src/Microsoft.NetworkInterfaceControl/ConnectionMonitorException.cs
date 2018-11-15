using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.Serialization;

namespace Microsoft.NetworkInterfaceControl
{
    public class ConnectionMonitorException : System.Exception, ISerializable
    {
        public ConnectionMonitorException() :base()
        {
        }
        public ConnectionMonitorException(string message) :base(message)
        {
        }
        public ConnectionMonitorException(string message, Exception inner) : base(message,inner)
        {
        }

        // This constructor is needed for serialization.
        protected ConnectionMonitorException(SerializationInfo info, StreamingContext context) :base(info,context)
        {
            // Add implementation.
        }
    }


}

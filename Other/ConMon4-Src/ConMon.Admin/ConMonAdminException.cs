using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ConMon.Admin
{
    /// <summary>
    /// Exceptions that are known and caught by ConMonAdmin application
    /// </summary>
    public class ConMonAdminException : Exception
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="message">Error message</param>
        public ConMonAdminException(string message)
            : base(message)
        {
        }
    }
}

using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Text;
using System.IO;
using System.Xml;
using System.Globalization;
using Microsoft.Practices.EnterpriseLibrary.Common.Configuration;
using Microsoft.Practices.EnterpriseLibrary.Logging;
using Microsoft.Practices.EnterpriseLibrary.Logging.Configuration;
using Microsoft.Practices.EnterpriseLibrary.Logging.Formatters;

namespace ConnectionMonitor.Logging
{
    /// <summary>
    /// Formats log data into xml
    /// </summary>
    [ConfigurationElementType(typeof(CustomFormatterData))]
    public class ConMonXmlFormatter : LogFormatter
    {
        /// <summary>
        /// Attributes passed at construction
        /// </summary>
        private NameValueCollection _attributes = null;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="attributes">Attributesw</param>
        public ConMonXmlFormatter(NameValueCollection attributes) : base()
        {
            this._attributes = attributes;
        }

        /// <summary>
        /// Formats a log entry into xml
        /// </summary>
        /// <param name="log">LogEntry to be formatted</param>
        /// <returns>Xml string containing the log entry to be written</returns>
        public override string Format(LogEntry log)
        {
            string returnValue = null;

            using(StringWriter sw = new StringWriterWithEncoding(new StringBuilder(), Encoding.UTF8))
            {
                XmlTextWriter w = new XmlTextWriter(sw);

                w.Formatting = Formatting.Indented;
                w.Indentation = 2;

                w.WriteStartDocument(true);
                w.WriteStartElement("LogEntry");

                w.WriteAttributeString("Timestamp", TimeZone.CurrentTimeZone.ToLocalTime(log.TimeStamp).ToString("G"));
                w.WriteAttributeString("Message", log.Message);
                w.WriteAttributeString("Category", log.CategoriesStrings[0].ToString());
                w.WriteAttributeString( "Priority", log.Priority.ToString( ) );
                w.WriteAttributeString( "EventId", log.EventId.ToString( CultureInfo.InvariantCulture ) );
                w.WriteAttributeString( "Severity", log.Severity.ToString( ) );
                w.WriteAttributeString( "Title", log.Title );
                w.WriteAttributeString( "Machine", log.MachineName );
                w.WriteAttributeString( "AppDomain", log.AppDomainName );
                w.WriteAttributeString( "ProcessId", log.ProcessId );
                w.WriteAttributeString( "ProcessName", log.ProcessName );
                w.WriteAttributeString( "Win32ThreadId", log.Win32ThreadId );
                w.WriteAttributeString( "ThreadName", log.ManagedThreadName );

                w.WriteEndElement();
                w.WriteEndDocument();
                returnValue =  sw.ToString().Substring(57);
            }

            return returnValue;
        }
    }

    public class StringWriterWithEncoding : StringWriter
    {
        private Encoding _encoding;

        public StringWriterWithEncoding(StringBuilder sb, Encoding encoding)
            : base(sb)
        {
            this._encoding = encoding;
        }

        public override Encoding Encoding
        {
            get
            {
                return this._encoding;
            }
        }
    }
}

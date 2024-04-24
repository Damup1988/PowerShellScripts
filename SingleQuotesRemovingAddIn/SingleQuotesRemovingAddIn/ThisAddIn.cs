using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using Outlook = Microsoft.Office.Interop.Outlook;
using Office = Microsoft.Office.Core;
using Microsoft.Office.Interop.Outlook;

namespace SingleQuotesRemovingAddIn
{
    public partial class ThisAddIn
    {
        private Items _items;

        private void ThisAddIn_Startup(object sender, System.EventArgs e)
        {
            // Get the Application object
            Outlook.Application application = this.Application;
            Outlook.NameSpace appNameSpace = application.GetNamespace("MAPI");
            Outlook.Folder sentFolder = appNameSpace.GetDefaultFolder(Outlook.OlDefaultFolders.olFolderSentMail) as Outlook.Folder;

            // Subscribe RemoveSingleQuots to event - new item in Sent Items folder

            _items = sentFolder.Items;
            _items.ItemAdd += new Outlook.ItemsEvents_ItemAddEventHandler(RemoveSingleQuots);
            //sentFolder.Items.ItemAdd += new Outlook.ItemsEvents_ItemAddEventHandler(RemoveSingleQuots);
        }

        private void ThisAddIn_Shutdown(object sender, System.EventArgs e)
        {
            // Note: Outlook no longer raises this event. If you have code that 
            //    must run when Outlook shuts down, see https://go.microsoft.com/fwlink/?LinkId=506785
        }

        #region VSTO generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisAddIn_Startup);
            this.Shutdown += new System.EventHandler(ThisAddIn_Shutdown);
        }

        #endregion

        void RemoveSingleQuots(object item)
        {
            Outlook.MailItem mailItem = (Outlook.MailItem)item;
            mailItem.To = mailItem.To.Replace("'", "");
            mailItem.Save();
        }
    }
}
using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Office.Interop.Outlook;

namespace SingleQuotesRemovingAddIn
{
    public partial class ThisAddIn
    {
        private Items _items;

        private void ThisAddIn_Startup(object sender, System.EventArgs e)
        {
            // Get the Application object
            Application application = this.Application;
            NameSpace appNameSpace = application.GetNamespace("MAPI");
            Folder sentFolder = appNameSpace.GetDefaultFolder(OlDefaultFolders.olFolderSentMail) as Folder;

            // Subscribe RemoveSingleQuots to event - new item in Sent Items folder

            _items = sentFolder.Items;
            _items.ItemAdd += new ItemsEvents_ItemAddEventHandler(RemoveSingleQuots);
        }

        private void ThisAddIn_Shutdown(object sender, EventArgs e)
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
            string result = null;
            MailItem mailItem = (MailItem)item;
            if (mailItem.To.Contains("'"))
            {
                Recipients recipients = mailItem.Recipients;

                List<string> to = new List<string>();
                foreach (Recipient recipient in recipients)
                {
                    if (recipient.Type == 1)
                    {
                        string name = recipient.Name.Replace("'", "");

                        string finalTo = null;
                        if (recipient.Name.Replace("'", "") == recipient.Address)
                        {
                            finalTo = name;
                        }
                        else
                        {
                            finalTo = name + " " + "<" + recipient.Address + ">";
                        }
                        to.Add(finalTo);
                    }
                }
                result = String.Join(";", to.ToArray());
            }
            mailItem.To = result;
            mailItem.Recipients.ResolveAll();
            mailItem.Save();
        }
    }
}
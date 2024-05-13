using Microsoft.Office.Interop.Outlook;
using Microsoft.Office.Tools.Ribbon;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Outlook = Microsoft.Office.Interop.Outlook;

namespace SingleQuotesRemovingAddIn
{
    public partial class Ribbon1
    {
        private Items _items;

        private void Ribbon1_Load(object sender, RibbonUIEventArgs e)
        {

        }

        private void button1_Click(object sender, RibbonControlEventArgs e)
        {
            Application outlookApp = new Outlook.Application();
            NameSpace appNameSpace = outlookApp.GetNamespace("MAPI");
            Folder sentFolder = appNameSpace.GetDefaultFolder(OlDefaultFolders.olFolderSentMail) as Folder;

            _items = (Items)sentFolder.Items;
            foreach (object item in _items)
            {
                MailItem mailItem = item as MailItem;
                if (mailItem != null)
                {
                    if (mailItem.To.Contains("'"))
                    {
                        mailItem.To = mailItem.To.Replace("'", "");
                    }
                    mailItem.Save();
                }
            }
        }
    }
}
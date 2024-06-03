using Microsoft.Office.Interop.Outlook;
using Microsoft.Office.Tools.Ribbon;
using System;
using System.Collections.Generic;
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
                string result = null;
                MailItem mailItem = item as MailItem;
                if (mailItem != null)
                {
                    if (mailItem.To != null && mailItem.To.Contains("'"))
                    {
                        Recipients recipients = mailItem.Recipients;
                        List<string> to = new List<string>();
                        foreach (Recipient recipient in recipients)
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
                        result = String.Join(";", to.ToArray());
                        mailItem.To = result;
                        mailItem.Recipients.ResolveAll();
                        mailItem.Save();
                    }
                }
            }
        }
    }
}
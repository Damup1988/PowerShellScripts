$email = 'abhay.rastogi@petrofac.com'

$InactiveMailbox = Get-ExoMailbox -InactiveMailboxOnly -Identity $email

$mailbox_table = @()

foreach ($guid in ($InactiveMailbox.Guid | select -ExpandProperty Guid))

{

    $mailbox_row = "" | select Guid, DisplayName, TotalItemSize, ArchiveDisplayName, ArchiveTotalItemSize, WhenSoftDeleted

    $mailbox = Get-MailboxStatistics -IncludeSoftDeletedRecipients -Identity $guid | Select DisplayName, TotalItemSize

    $mailbox_row.Guid = $guid

    $mailbox_row.DisplayName = $mailbox.DisplayName;

    $mailbox_row.TotalItemSize = $mailbox.TotalItemSize;

    $mailbox_row.WhenSoftDeleted = Get-Mailbox -InactiveMailboxOnly -Identity $guid | select -ExpandProperty WhenSoftDeleted

    try

    {

        $mailbox = Get-MailboxStatistics -IncludeSoftDeletedRecipients -Identity $guid -Archive -ErrorAction Stop | Select DisplayName, TotalItemSize

        $mailbox_row.ArchiveDisplayName = $mailbox.DisplayName;

        $mailbox_row.ArchiveTotalItemSize = $mailbox.TotalItemSize;

    }

    catch { "The Archive Mailbox is not enabled for $guid" }

    $mailbox_table += $mailbox_row

}

$mailbox_table | ft -AutoSize
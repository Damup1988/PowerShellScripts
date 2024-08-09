Connect-ExchangeOnline

Get-Mailbox | Get-MailboxStatistics | Select DisplayName, TotalItemSize, StorageLimitStatus, ItemCount, `
@{Name="ProhibitSendReceiveQuota";Expression={[math]::Round(($_.ProhibitSendReceiveQuota/1MB),2)}}, `
@{Name="ProhibitSendQuota";Expression={[math]::Round(($_.ProhibitSendQuota/1MB),2)}} | `
Export-Csv -Path "C:\MailboxReport.csv" -NoTypeInformation

Get-EXOMailbox -UserPrincipalName "damir.safarov@petrofac.com" | select *

Get-EXOMailbox -Identity "damir.safarov@petrofac.com" | Select-Object DisplayName, ItemCount, `
@{Name="TotalItemSize (MB)";Expression={[math]::Round(($_.TotalItemSize/1MB),2)}} | `
Format-Table -AutoSize

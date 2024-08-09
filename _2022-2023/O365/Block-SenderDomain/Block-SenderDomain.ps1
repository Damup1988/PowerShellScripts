Connect-ExchangeOnline

$rootPath = "C:\_bufer\_scripts\O365\Block-SenderDomain"
$log = "$($rootPath)\log.txt"
$list = Get-Content -Path "$($rootPath)\toBlock.txt"

#Connect-ExchangeOnline
foreach ($domain in $list) {
    Set-HostedContentFilterPolicy -Identity "All Other mail domains." -BlockedSenderDomains @{add="$domain"}
    "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss") - $($domain) has been added to the block list" >> $log
    write-host "$domain" -foregroundcolor yellow
}

$defaultPolicy = Get-HostedContentFilterPolicy -Identity "All Other mail domains."
$defaultPolicy | `
    ForEach-Object {write-host ("`r`n"*3)$_.Name,`r`n,("="*79),`r`n,"Blocked Sender Domains",`r`n,("-"*79),`r`n,$_.BlockedSenderDomains}

# The domain has been added to the block list
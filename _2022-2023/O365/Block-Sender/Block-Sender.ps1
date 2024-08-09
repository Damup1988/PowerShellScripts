$rootPath = "C:\_bufer\_scripts\O365\Block-Sender"
$log = "$($rootPath)\log.txt"
$list = Get-Content -Path "$($rootPath)\list.txt"

Connect-ExchangeOnline
foreach ($sender in $list) {
    Set-HostedContentFilterPolicy -Identity "All Other mail domains." -BlockedSenders @{add="$sender"}
    "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss") - $($sender) has been added to the block list" >> $log
}

$defaultPolicy = Get-HostedContentFilterPolicy -Identity "All Other mail domains."
$defaultPolicy | ForEach-Object {write-host ("`r`n"*3)$_.Name,`r`n,("="*79),`r`n,"Blocked Sender Domains",`r`n,("-"*79),`r`n,$_.BlockedSenderDomains}

# The domain has been added to the block list
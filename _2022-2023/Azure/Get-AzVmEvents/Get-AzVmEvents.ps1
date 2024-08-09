Connect-AzAccount

$dir = "C:\Users\damup1988\OneDrive - Petrofac\_bufer\_scripts\Azure\Get-AzVmEvents"
$subs = Get-Content -Path "$dir\subs.txt"
$newList = New-Item -Path "$dir\Reports" -Name "$(Get-Date -Format 'dd.MM.yyyy.HH.mm.ss').FailedVMs.txt" -Type File

foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub
    $allVMs = Get-AzVM
    foreach ($vm in $allVMs) {
        $allLogs = Get-AzActivityLog -ResourceId $vm.Id `
            -StartTime $(Get-Date).AddHours(-24) `
            | Where-Object {$_.Category -eq "Resource Health" -and $_.level -eq "Critical"} `
            | Where-Object {$_.Properties.Content.type -eq "downtime"}
        if ($allLogs -ne $null) {
            Write-Host "$($vm.Name)" -ForegroundColor Red
            "$($vm.Name);$($vm.location);$($vm.HardwareProfile.VmSize);$sub" >> $newList.FullName
        }
    }
}

#| Where-Object {$_.EventTimestamp -ge $(Get-Date -Day 30 -Month 11 -Year 2023)}
#| Where-Object {$_.Properties.Content.previousHealthStatus -eq "Available" -and $_.Properties.Content.currentHealthStatus -eq "Unavailable"}
$VMsToCheck = Get-Content -Path "C:\_bufer\_scripts\Azure\Check-VmExistance\list.txt"
$subs = @()
$subs += 'ff8ea09d-a6a9-482a-a209-58f43068b627'
$subs += 'a4e55b46-81ca-4194-9d50-0a051971392e'

foreach ($azvm in $VMsToCheck) {
    $exists = $false
    foreach ($sub in $subs) {
        $x = Select-AzSubscription -SubscriptionId $sub
        $vm = Get-AzVM -Name $azvm
        if ($null -eq $vm -and $exists -ne $true) {
            $exists = $false
        }
        else {
            $exists = $true
        }
    }
    if ($exists) {
        Write-Host "$azvm" -ForegroundColor Yellow
        $azvm >> "C:\_bufer\_scripts\Azure\Check-VmExistance\existingVMs.txt"
    }
    else {
        Write-Host "$azvm" -ForegroundColor Red
        $azvm >> "C:\_bufer\_scripts\Azure\Check-VmExistance\notExistingVMs.txt"
    }
}
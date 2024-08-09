#Connect-AzAccount

#$AzureSubscriptionID = "ff8ea09d-a6a9-482a-a209-58f43068b627"
#$rgName = "RG-SAS-PRD-VDI"
$AzureSubscriptionID = "cc9fdec6-f426-416d-82d1-41260d9860ef"
$rgName = "RG-EUN-MAIN"

Set-AzContext -SubscriptionId $AzureSubscriptionID
#$hosts = Get-AzVM | Where-Object {$_.Name -like "VDI-HF48*"}
$hosts = Get-AzVM

$hostsState = @()
foreach ($vm in $hosts) {
    $MyTable = New-Object System.Object
    $MyTable | Add-Member -Type NoteProperty -Name "hostName" -Value $vm.Name
    $hostState = $(Get-AzVM -VMName $vm.Name -Status).PowerState
    if ($hostState -eq "VM running") {
        $MyTable | Add-Member -Type NoteProperty -Name "State" -Value $hostState
    }
    else {
        $MyTable | Add-Member -Type NoteProperty -Name "State" -Value $hostState
    }
    $hostsState += $MyTable
}

$hostsState

$Jobs = @()
foreach ($vm in $hostsState) {
    if ($vm.State -eq "VM deallocated") {
        $Job = Start-Azvm -Name $vm.hostName -ResourceGroupName $rgName -asjob
        $Jobs += $job
    }
}

Wait-Job -Job $Jobs
$jobs | Receive-Job
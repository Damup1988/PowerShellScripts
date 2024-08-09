Connect-AzAccount

$AzureSubscriptionID = "ff8ea09d-a6a9-482a-a209-58f43068b627"
$rgName = "RG-SAS-PRD-VDI"

Set-AzContext -SubscriptionId $AzureSubscriptionID
$hosts = Get-AzVM | Where-Object {$_.Name -like "VDI-HF48*"}

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
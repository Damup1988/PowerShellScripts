$hostName = "VDI-HF7219-16a7"
$subId = "ff8ea09d-a6a9-482a-a209-58f43068b627"
$rg = "RG-SAS-PRD-VDI"

$vmID = $(Get-AzVM -ResourceGroupName $rg -Name $hostName).Id
$allEvents = Get-AzActivityLog -ResourceId $vmID
$allEventsToday = $allEvents | ? {$_.EventTimeStamp.ToShortDateString() -eq $(Get-Date -Format 'dd/MM/yyyy')}
$allEventsTodayCritical = $allEventsToday | ? {$_.level -eq "Critical"}
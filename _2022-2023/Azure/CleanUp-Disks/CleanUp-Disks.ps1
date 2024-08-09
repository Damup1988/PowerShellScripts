$disks = Get-Content -Path "C:\_bufer\_scripts\Azure\CleanUp-Disks\list_RITM0394407.txt"

$tags = @{}
$tags += @{ "AssignedTo" = "Damir Safarov"}
$tags += @{ "ApplicationName" = "Disk snapshot"}
$tags += @{ "ApplicationOwner" = "Damir Safarov"}
$tags += @{ "ITVertical" = "ITVertical"}
$tags += @{ "Environment" = "PRD"}
$tags += @{ "Change" = "RITM0394407"}
$tags += @{ "CreatedBy" = "virp_damrov@petrofac.com"}

$subs = Get-AzSubscription

$allDisks = @()
foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub.Id
    $allDisks += Get-AzDisk | Where-Object {$disks -contains $_.Name}
}

foreach ($disk in $allDisks) {
    Select-AzSubscription -SubscriptionId $disk.id.Split("/")[2]
    $snapshotConfig = New-AzSnapshotConfig `
        -SourceUri $disk.Id `
        -CreateOption Copy `
        -Location $disk.Location `
        -Tag $tags
    New-AzSnapshot `
        -Snapshot $snapshotConfig `
        -SnapshotName "$($disk.Name)_snapshot" `
        -ResourceGroupName $disk.ResourceGroupName
    Remove-AzDisk `
        -ResourceGroupName $disk.ResourceGroupName `
        -DiskName $disk.Name `
        -Force
}
$disks = Get-Content -Path "C:\_bufer\_scripts\PowerShellDamirSafarov\Create-DiskSnap\list.txt"

$tags = @{}
$tags += @{ "AssignedTo" = "Damir Safarov"}

$subs = Get-AzSubscription

$allDisks = @()
foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub.Id
    $allDisks += Get-AzDisk | Where-Object {$disks -contains $_.Name}
}

foreach ($disk in $allDisks) {
    $snapshotConfig = New-AzSnapshotConfig `
        -SourceUri $disk.Id `
        -CreateOption Copy `
        -Location $disk.Location `
        -Tag $tags
    New-AzSnapshot `
        -Snapshot $snapshotConfig `
        -SnapshotName "$($disk.Name)_snapshot" `
        -ResourceGroupName $disk.ResourceGroupNameNew
}
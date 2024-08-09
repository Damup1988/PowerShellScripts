$data = @()

Select-AzSubscription -SubscriptionId "aaeca9fd-f156-4439-882e-7a446a0203b4"
$allRG = Get-AzResourceGroup
foreach ($RG in $allRG) {
    #$allResources = Get-AzResource -ResourceGroupName $RG.ResourceGroupName
    $allResources = Get-AzResource -ResourceGroupName "RG-SAS-001"
    foreach ($resource in $allResources) {
        $resourceTags = [PSCustomObject]@{
            ResourceName = $resource.Name
        }
        foreach ($tagKey in $resource.Tags.Keys) {
            $resourceTags | Add-Member -MemberType NoteProperty -Name $tagKey -Value  $resource.Tags[$tagKey]
        }
        $data += $resourceTags
    }
}
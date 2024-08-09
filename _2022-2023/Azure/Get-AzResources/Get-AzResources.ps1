Connect-AzAccount

$MGs = Get-AzManagementGroup

$allKeys = @()

foreach ($MG in $MGs) {
    $allSubs = Get-AzManagementGroupSubscription `
        -GroupId $MG.Name `
        | Where-Object {$_.DisplayName -notlike "*Active Directory"}
    foreach ($sub in $allSubs) {
        Select-AzSubscription -SubscriptionId $sub.Id.Split("/")[6]
        $allRG = Get-AzResourceGroup
        foreach ($RG in $allRG) {
            $allResources = Get-AzResource -ResourceGroupName $RG.ResourceGroupName
            foreach ($resource in $allResources) {
                $allKeys += $resource.Tags.Keys
            }
        }
    }
}

$uniqKeys = $allKeys | Select-Object -Unique

$uniqueValuesTable = @{}
$uniqKeysChecked = @()
foreach ($string in $uniqKeys) {
    if (-not $uniqueValuesTable.ContainsKey($string)) {
        $uniqueValuesTable[$string] = $true
        $uniqKeysChecked += $string
    }
}

$data = @()
foreach ($MG in $MGs) {
    $allSubs = Get-AzManagementGroupSubscription `
        -GroupId $MG.Name `
        | Where-Object {$_.DisplayName -notlike "*Active Directory"}
    foreach ($sub in $allSubs) {
        $subId = $sub.Id.Split("/")[6]
        Select-AzSubscription -SubscriptionId $subId
        $allRG = Get-AzResourceGroup
        foreach ($RG in $allRG) {
            $allResources = Get-AzResource -ResourceGroupName $RG.ResourceGroupName

            $count = 0
            foreach ($resource in $allResources) {
                $count++
                Write-Progress -Activity "Processing resources in $subId - $($RG.ResourceGroupName)" -PercentComplete (($count / $allResources.Count) * 100)

                $item = New-Object -Type PSObject
                $item | Add-Member -MemberType NoteProperty -Name "ManagementGroup"     -Value $MG.DisplayName
                $item | Add-Member -MemberType NoteProperty -Name "SubscriptionName"    -Value $sub.DisplayName
                $item | Add-Member -MemberType NoteProperty -Name "SubscriptionId"      -Value $subId
                $item | Add-Member -MemberType NoteProperty -Name "ResourceGroup"       -Value $RG.ResourceGroupName
                $item | Add-Member -MemberType NoteProperty -Name "ResourceName"        -Value $resource.Name
                $item | Add-Member -MemberType NoteProperty -Name "AzResourceType"      -Value $resource.Type
                #$item | Add-Member -MemberType NoteProperty -Name "Sku"                 -Value $resource.Sku
                $item | Add-Member -MemberType NoteProperty -Name "Location"            -Value $resource.Location
                <#foreach ($tag in $resource.Tags) {
                    $item | Add-Member -MemberType NoteProperty -Name "$($tag.Key)"     -Value $tag.Values
                }#>

                foreach ($key in $uniqKeysChecked) {
                    if ($resource.Tags.Keys -contains $key) {
                        $item | Add-Member -MemberType NoteProperty -Name $key          -Value $resource.Tags[$key]
                    }
                    else {
                        $item | Add-Member -MemberType NoteProperty -Name $key          -Value ""
                    }
                }
                $data += $item
            }
        }
    }
}
# connect az account
Connect-AzAccount

# get all subs
$allSubs = Get-AzSubscription

foreach ($sub in $allSubs) {
    Select-AzSubscription -SubscriptionId $sub.Id
    Get-AzStorageAccount | Where-Object {$_.SkuName -eq "Standard_LRS"} | Select-Object StorageAccountName, SkuName
}
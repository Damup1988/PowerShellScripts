$SubscriptionId = "a4e55b46-81ca-4194-9d50-0a051971392e"
$ResourceGroupName = "RG-EUN-PRD-AVD-Storage"
$StorageAccountName = "saeunprdlzavd01fnc"
$SamAccountName = "saeunprdlzavd01fnc"
$DomainAccountType = "ComputerAccount"
$OuDistinguishedName = "OU=File Server,OU=PFC-Servers Global,DC=ds,DC=petrofac,DC=local"
$EncryptionType = "AES256"

Select-AzSubscription -SubscriptionId $SubscriptionId

Join-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -SamAccountName $SamAccountName `
        -DomainAccountType $DomainAccountType `
        -OrganizationalUnitDistinguishedName $OuDistinguishedName `
        -EncryptionType $EncryptionType

Update-AzStorageAccountAuthForAES256 -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose
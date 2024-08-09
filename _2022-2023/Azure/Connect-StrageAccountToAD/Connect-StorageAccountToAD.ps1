# Create the Kerberos key on the storage account and get the Kerb1 key as the password for the AD identity 
# to represent the storage account
$ResourceGroupName = "RG-EUN-DEV-DataLake-03"
$StorageAccountName = "dlseundevdlshared01"

New-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -KeyName kerb1
Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ListKerbKey | where-object {$_.Keyname -contains "kerb1"}

Setspn -S cifs/your-storage-account-name-here.file.core.windows.net dlseundevdlshared01
Set-ADAccountPassword -Identity dlseundevdlshared01$ -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "kerb1_key_value_here" -Force)

# Set the feature flag on the target storage account and provide the required AD domain information
Set-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName `
        -EnableActiveDirectoryDomainServicesForFile $true `
        -ActiveDirectoryDomainName "ds.petrofac.local" `
        -ActiveDirectoryNetBiosDomainName "ds.petrofac.local" `
        -ActiveDirectoryForestName "petrofac.local" `
        -ActiveDirectoryDomainGuid "db93a531-4470-4dcb-a511-5dd069347c93" `
        -ActiveDirectoryDomainsid "S-1-5-21-3942209672-780422606-102645127" `
        -ActiveDirectoryAzureStorageSid "S-1-5-21-3942209672-780422606-102645127-525090" `
        -ActiveDirectorySamAccountName "DLSEUNDEVDLSHAR$" `
        -ActiveDirectoryAccountType "Computer"

$storageaccount = Get-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName

$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties
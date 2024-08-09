Connect-AzureAD

$aadGroupName = "WDATP-IBM"

Get-AzureADGroup -SearchString $aadGroupName `
    | Get-AzureADGroupMember `
    | Select-Object DisplayName,UserPrincipalName,UserType `
    | Export-Csv -Path "$($aadGroupName).csv" -Delimiter ',' -NoTypeInformation
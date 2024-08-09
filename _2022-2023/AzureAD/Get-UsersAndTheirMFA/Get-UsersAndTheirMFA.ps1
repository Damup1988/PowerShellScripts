$allUsers = Get-AzureADUser -All $true | Where-Object {$_.AccountEnabled -eq $true}

$total = $allUsers.Count
$total
$current = 0

$result = @()
foreach ($user in $allUsers) {
    $current++
    Write-Progress `
        -Activity 'Processing computers' `
        -CurrentOperation $user.UserPrincipalName `
        -PercentComplete (($current / $total) * 100)
    $upn = $user.UserPrincipalName
    $MFAMethods = (Get-MsolUser -UserPrincipalName $user.UserPrincipalName `
        | Select-Object StrongAuthenticationMethods).StrongAuthenticationMethods
    foreach ($method in $MFAMethods) {
        $result += "$($upn);$($method.IsDefault);$($method.MethodType)"
    }
}

$result >> result.txt
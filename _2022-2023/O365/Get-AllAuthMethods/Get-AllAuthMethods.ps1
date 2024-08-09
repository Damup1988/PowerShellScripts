#$allUsers = Get-MsolUser -All

$myData = @()
$counter = 0
foreach ($user in $allUsers) {
    $counter++
    Write-Progress -Activity "Processing..." -CurrentOperation $user.UserPrincipalName -PercentComplete (($counter / $allUsers.Count) * 100)

    $allUserAuthMethods = $user.strongAuthenticationMethods
    foreach ($method in $allUserAuthMethods) {
        $MyTable = New-Object System.Object
        $MyTable | Add-Member -Type NoteProperty -Name "UPN" -Value $user.UserPrincipalName
        $MyTable | Add-Member -Type NoteProperty -Name "AuthMethod" -Value $method.MethodType
        $MyTable | Add-Member -Type NoteProperty -Name "IsDefault" -Value $method.IsDefault
        $myData += $MyTable     
    }    
}

$myData | Export-Csv -Delimiter ';' -Path "C:\_bufer\_scripts\O365\Get-AllAuthMethods\data2.csv"
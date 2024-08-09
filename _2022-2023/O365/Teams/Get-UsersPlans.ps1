Connect-MicrosoftTeams

$users = Import-Csv -Path "C:\_bufer\_scripts\O365\Teams\users.csv" -Delimiter ','

$counter = 0
foreach ($user in $users) {
    $counter++
    Write-Progress -Activity "Processing..." -CurrentOperation $user.UserPrincipalName -PercentComplete (($counter / $users.Count) * 100)

    Write-Host "$($user.UserPrincipalName)" -ForegroundColor Blue
    $policies = Get-CsUserPolicyAssignment -Identity $user.UserPrincipalName
    $routingPol = ($policies | Where-Object {$_.PolicyType -eq "OnlineVoiceRoutingPolicy"}).PolicyName
    $dialPlan = ($policies | Where-Object {$_.PolicyType -eq "TenantDialPlan"}).PolicyName
    if ($routingPol -eq "Category 3" -and $dialPlan -eq "Petrofac-Tower1") {
        "$($user.UserPrincipalName),$($user.'msRTCSIP-Line')" >> "C:\_bufer\_scripts\O365\Teams\out.txt"
    }
    else {
        Write-Host "$($user.UserPrincipalName) doesn't have required policies" -ForegroundColor Yellow
    }
}
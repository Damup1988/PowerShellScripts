#Connect to Exchange Online
Connect-ExchangeOnline

$users = Get-Content -path "C:\_bufer\_scripts\O365\Add-UserToGroupBulk\list.txt"

$counter = 0
foreach ($user in $users) {
    $counter++
    Write-Progress -Activity "Processing..." -CurrentOperation $user -PercentComplete (($counter / $users.Count) * 100)

    $userToCheck = Get-AzureADUser -SearchString $user
    if ($userToCheck -ne $null) {        
        $user >> "C:\_bufer\_scripts\O365\Add-UserToGroupBulk\finalList.txt"
    }
    else {
        $user >> "C:\_bufer\_scripts\O365\Add-UserToGroupBulk\cantFindUsers.txt"
        Write-Host "Can't find $($user)" -ForegroundColor Yellow
    }
}
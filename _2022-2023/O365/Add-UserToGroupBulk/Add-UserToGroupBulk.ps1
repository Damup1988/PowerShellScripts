#Connect to Exchange Online
Connect-ExchangeOnline

$users = Get-Content -path "C:\_bufer\_scripts\O365\Add-UserToGroupBulk\finalList.txt"
$groupName = "PetrofacStepsChallenge@PetrofacOnline.onmicrosoft.com"

$counter = 0
foreach ($user in $users) {
    $counter++
    Write-Progress -Activity "Processing..." -CurrentOperation $user -PercentComplete (($counter / $users.Count) * 100)

    #PowerShell to add a user to office 365 group
    Add-UnifiedGroupLinks -Identity $groupName -LinkType "Members" -Links $user
}
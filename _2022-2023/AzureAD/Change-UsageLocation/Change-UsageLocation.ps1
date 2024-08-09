#Connect to Azure AD
Connect-MsolService

$users = Get-Content -Path "C:\Users\damir.safarov\OneDrive - EPAM\Docs\INC0553035affectedusers.txt"

foreach ($user in $users) {
    $user = Get-MsolUser -UserPrincipalName $user
    Set-MsolUser -ObjectId $user.ObjectId -UsageLocation "TH"
}
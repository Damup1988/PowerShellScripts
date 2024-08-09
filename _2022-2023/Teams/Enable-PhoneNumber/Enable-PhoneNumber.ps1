$logs = "C:\_bufer\_scripts\Teams\Enable-PhoneNumber\logs.txt"

# Office 365 E5 license must be assigned for user. If not GSD could assign after Sameer has approve.
$user = "simona.fernandes@petrofac.com"
$phoneNumbers = "Tel:+97165173075;Ext=73075"
 
$dialPolicy = "Petrofac-Tower1"
$routePolicy = "Category 3"
 
# in onprem AD
$reqUser = Get-ADUser -Filter * | Where-Object {$_.UserPrincipalName -eq "$user"}
Set-ADUser $reqUser -Replace @{"msRTCSIP-Line" = "$phoneNumbers"}​​​​​
 
Connect-MicrosoftTeams
Grant-CsTenantDialPlan -Identity $user -PolicyName $dialPolicy
Grant-CsOnlineVoiceRoutingPolicy -Identity $user -PolicyName $routePolicy
try {
    Set-CsPhoneNumberAssignment -Identity $user -EnterpriseVoiceEnabled $true
    "$(Get-Date): dial up  has been enabled for $($user)" >> $logs
}
catch {
    "$(Get-Date): couldn't enable dial up for $($user)" >> $logs
}
Disconnect-MicrosoftTeams
# cloud part

$dialPpolicy = "Petrofac-Tower1" # Petrofac-Tower1
$routePolicy = "Category 3" # Category 3
$userEmail = "Elias.Chouaifati@petrofac.com" # damir.safarov@petrofac.com

Connect-MicrosoftTeams

Grant-CsTenantDialPlan -Identity $userEmail -PolicyName $dialPpolicy
Grant-CsOnlineVoiceRoutingPolicy -Identity $userEmail -PolicyName $routePolicy
Set-CsPhoneNumberAssignment -Identity $userEmail -EnterpriseVoiceEnabled $true
#Connect to Azure AD
Connect-MsolService

$users = Get-Content -Path "C:\Users\damir.safarov\OneDrive - EPAM\Docs\INC0553035affectedusers.txt"

foreach ($user in $users) {
    #Get the user you want to force to re-register MFA
    $user = Get-MsolUser -UserPrincipalName $user

    #Create a new MFA requirement object that requires the user to re-register MFA
    $requirement = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $requirement.RelyingParty = "*"
    $requirement.State = "Enforced"
    $requirement.RememberDevicesNotIssuedBefore = (Get-Date)

    #Set the user's MFA requirements to the new requirement object
    Set-MsolUser -UserPrincipalName $user.UserPrincipalName -StrongAuthenticationRequirements @($requirement)
}
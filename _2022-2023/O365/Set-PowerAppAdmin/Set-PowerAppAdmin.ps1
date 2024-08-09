# required modules
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser
Install-Module -Name Microsoft.PowerApps.PowerShell -AllowClobber -Scope CurrentUser

# connect to power app
Add-PowerAppsAccount

# get all the environments
Get-PowerAppEnvironment `
    | Select-Object EnvironmentName,DisplayName

Connect-MsolService
$user = Get-MsolUser `
    -UserPrincipalName "virp_damrov@petrofac.com" `
    | Select-Object *

# list all power apps within an environment
Get-AdminPowerApp `
    -EnvironmentName "Default-16a4d712-85ca-455c-bba0-139c059e16e3" `
    | Select-Object AppName,DisplayName

# assign an owner to a power app
Set-AdminPowerAppOwner `
    -AppName "04c5e056-d6a6-4c99-a2fd-3797cc0f5d9b" `
    -EnvironmentName "Default-16a4d712-85ca-455c-bba0-139c059e16e3" `
    -AppOwner $user.ObjectId

# list all the users assigned to a power app
Get-AdminPowerAppRoleAssignment `
    -EnvironmentName "Default-16a4d712-85ca-455c-bba0-139c059e16e3" `
    -AppName "04c5e056-d6a6-4c99-a2fd-3797cc0f5d9b" `
    | Select-Object PrincipalEmail,PrincipalType

# remove a used from power app where RoleId is the user's guid
Remove-AdminPowerAppRoleAssignment `
    -EnvironmentName "Default-16a4d712-85ca-455c-bba0-139c059e16e3" `
    -AppName "04c5e056-d6a6-4c99-a2fd-3797cc0f5d9b" `
    -RoleId ac927080-c7df-41a1-9068-b2593f633d68
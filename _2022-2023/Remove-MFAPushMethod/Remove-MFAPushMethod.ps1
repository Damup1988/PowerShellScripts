#Requires -module MSOnline
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [mailaddress]
    $UserUpn
)

<#
.SYNOPSIS
    This script removes PhoneAppNotification MFA setting for a specified user in MSOL.

.DESCRIPTION
    This script retrieves the specified user's MFA settings from MSOL, removes the PhoneAppNotification method, and updates the user's MFA settings.

.PARAMETER UserUpn
    Specifies the user's user principal name (UPN). This parameter is mandatory.

.NOTES
    The script requires the MSOnline PowerShell module to be installed and imported.
    Version: 1.1.0

.EXAMPLE
    PS> Remove-PushMFAMethod -UserUpn "user@contoso.com"
    This command removes the PhoneAppNotification MFA setting for the user with the specified UPN.
#>



function Remove-PhoneAppNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSCustomObject]
        $UserObject
    )

    $FixedMethods = @()
    $UserStrongAuthMethods = $UserObject.StrongAuthenticationMethods
    $IsPushDefaultMethod = ($UserStrongAuthMethods | where-object { $_.MethodType -eq "PhoneAppNotification" }).IsDefault

    
    foreach ($Method in $UserStrongAuthMethods) {

        if($Method.MethodType -ne "PhoneAppNotification"){
            if ($Method.MethodType -eq "PhoneAppOTP") {
                if ($IsPushDefaultMethod) {
                    $Method.IsDefault = $true
                }
                $FixedMethods += $Method
            }
            else{
                $FixedMethods += $Method
            }
            
        }
    }

    Set-MSolUser -ObjectId $UserObject.ObjectId -StrongAuthenticationMethods $FixedMethods
}

Write-Output "Checking MSOL Connection"
try{
    $Connection = Get-MsolDomain -ErrorAction Stop
}
catch{
    Write-Warning "MSOL Connection is not established. Trying to connect"
}

if (!$Connection) {
    try{
        Connect-MsolService -ErrorAction STOP
    }
    catch{
        Write-Error "Unable to connect to MSOL Service. $($_.Exception)"
        exit 1
    }
}

Write-Output "Getting MFA User"
$User = Get-MsolUser -UserPrincipalName $UserUpn -ErrorAction SilentlyContinue
if ($User) {
    Write-Output "User $($User.UserPrincipalName) - $($User.ObjectId) has been found"
    Write-Output "Users MFA Settings: `n $(
        foreach ($Method in $User.StrongAuthenticationMethods){
            Write-Output "Method: $($Method.MethodType) - Default: $($Method.IsDefault)`n"
        }
    )"
    Write-Output "Removing PhoneAppNotification from MFA Settings"
    try{
        Remove-PhoneAppNotification -UserObject $User -ErrorAction "STOP"
        Write-Output "PhoneAppNotification has been removed from MFA Settings"
    }
    catch{
        Write-Error "Unable to remove PhoneAppNotification from MFA Settings. $($_.Exception)"
        exit 1
    }

    $User = Get-MsolUser -UserPrincipalName $UserUpn
    Write-Output "User mfa settings after changes: `n $(
        foreach ($Method in $User.StrongAuthenticationMethods){
            Write-Output "Method: $($Method.MethodType) - Default: $($Method.IsDefault)`n"
        }
    )"
}
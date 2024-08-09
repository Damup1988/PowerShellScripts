Get-LocalUser

$Password = ConvertTo-SecureString "P@ssW0rD!" -AsPlainText -Force -Verbose
$Password
$UserAccount = Get-LocalUser -Name "tempadmin"
$UserAccount | Set-LocalUser -Password $Password

New-LocalUser `
    -Name "tempadmin" `
    -Password (ConvertTo-SecureString "BArakuda@123@759" -AsPlainText -Force)

Add-LocalGroupMember -Group "Administrators" -Member "tempadmin"
Get-LocalUser
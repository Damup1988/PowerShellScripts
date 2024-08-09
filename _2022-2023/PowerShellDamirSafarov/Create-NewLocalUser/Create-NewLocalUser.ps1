$securePassword = ConvertTo-SecureString "EWcuvbb@123" -AsPlainText -Force
New-LocalUser "tempUser" -Password $securePassword -FullName "tempUser" -Description "temp user"
Add-LocalGroupMember -Group "Administrators" -Member "tempUser"
Get-LocalUser
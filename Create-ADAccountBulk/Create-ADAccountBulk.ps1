$UsersToCreate = Get-Content "C:\Users\dutyadmin\Documents\UsersToCreate.txt"

foreach ($u in $UsersToCreate) {
    New-ADUser `
        -Name $u `
        -GivenName "" `
        -Surname $SurName `
        -DisplayName $u `
        -OfficePhone "8333" `
        -UserPrincipalName "$u@source.local" `
        -AccountPassword (ConvertTo-SecureString "BArakuda@123" -AsPlainText -Force) `
        -Path "OU=Service Accounts,OU=SOURCECORP,DC=SOURCE,DC=local" `
        -ChangePasswordAtLogon $false `
        -PasswordNeverExpires $true `
        -Enabled $true
}
$password = Read-Host -AsSecureString
$key = ConvertFrom-SecureString -SecureString $password
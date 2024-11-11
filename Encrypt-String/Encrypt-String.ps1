$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
$key = New-Object Byte[] 32
$rng.GetBytes($key)
$keyFilePath = "C:\PKI\script\file.key"
$key > $keyFilePath


[Byte[]]$keyContent = Get-Content -Path $keyFilePath
$password = "BArakuda@123"
$secString = ConvertTo-SecureString $password -AsPlainText -Force
$encryptedString = ConvertFrom-SecureString -SecureString $secString -Key $keyContent
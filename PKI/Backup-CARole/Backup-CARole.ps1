$backupFolder = "C:\scripts\Backup-CARole"
$key = Get-Content "$backupFolder\key.txt"
$password = ConvertTo-SecureString -String $key
$NewBackupFolder = New-Item -Path $backupFolder -Name "$(Get-Date -Format 'dd.MM.yyyy.HH.mm.ss')" -ItemType Directory

Backup-CARoleService -Path $NewBackupFolder.FullName -Password $password
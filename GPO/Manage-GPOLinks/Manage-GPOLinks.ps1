#Implementation
$rootPath = "C:\temp"
$server = "ipgphotonics.com"
$Links = Import-Csv -Path "C:\temp\LinksToBeDeleted.csv" -Delimiter ';'
$logFile = New-Item -Name "$(Get-Date -Format 'dd.MM.yyyy.HH.mm.ss').RFCXXX.csv" -Path $rootPath
"Date;GpoName;OU;Reason" > $logFile.FullName

foreach ($link in $Links) {
    $computerAccounts = @()
    $computerAccounts += `
        Get-ADComputer `
            -Server $server `
            -SearchBase $link.OU `
            -Filter * `
            | Where-Object {$_.enabled -eq $true}
    $userAccounts = @()
    $userAccounts += `
        Get-ADUser `
            -Server $server `
            -SearchBase $link.OU `
            -Filter * `
            | Where-Object {$_.enabled -eq $true}
    if ($computerAccounts.count -ne 0 -or $userAccounts.count -ne 0) {
        Write-Host "WARNING! $($link.OU) contains enabled computer or user accounts" -ForegroundColor Yellow
    }
    else {
        Remove-GPLink -Name $link.GpoName -Target $link.OU
        "$(Get-Date -Format 'dd.MM.yyyy HH:mm:ss');$($link.GpoName);$($link.OU);$($link.Reason)" >> $logFile.FullName
    }
}

#RollBack
$linksToRestore = Import-Csv -Path "C:\temp\14.03.2024.05.30.34.RFCXXX.csv" -Delimiter ';'
foreach ($link in $linksToRestore) {
    New-GPLink -Name $link.gpoName -Target $link.OU   
}
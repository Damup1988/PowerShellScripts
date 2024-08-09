Connect-ExchangeOnline

$rootPath = "C:\_bufer\_scripts\O365\Exchange\Get-LastMessageDateForDL90Days"

$reportsFolder = "$rootPath\reports"
$batchesFolder = "$rootPath\batches\16082023_102840"

$batchFiles = Get-ChildItem -Path $batchesFolder -Recurse `
    | Where-Object {$_.Mode -eq "-a----"} `
    | Where-Object {$_.Name -like "*send*" -or $_.Name -like "*receive*"}

[system.Diagnostics.Process]::Start("chrome","--incognito https://admin.microsoft.com")
foreach ($file in $batchFiles) {
    $id = $file.Name.Split('_')[3].Replace(".txt", "")
    $url = (Get-HistoricalSearch -JobId $id).FileUrl
    if ($url -eq $null) {
        Write-Host "No data for batch: $($file.Name)"
    }
    else {
        [system.Diagnostics.Process]::Start("chrome","--incognito $url")
    }
}
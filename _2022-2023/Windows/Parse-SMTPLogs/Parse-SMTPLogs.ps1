$logsFolder = "C:\_bufer\_scripts\Windows\Parse-SMTPLogs\SMTP002SLOGBR"
$logFiles = Get-ChildItem -Path $logsFolder

$total = $logFiles.Count
Write-Host "Total files: $($total)"
$current = 0

$result = @()
foreach ($logFile in $logFiles) {
    $current++
    Write-Progress `
        -Activity "Processing log files" `
        -CurrentOperation $logFile.Name `
        -PercentComplete (($current / $total) * 100)

    $data = Get-Content -Path $logFile.FullName

    $total2 = $data.Count
    Write-Host "Total entries: $($total2)"
    $current2 = 0

    foreach ($entry in $data) {
        $current2++
        Write-Progress `
            -Activity "Processing entry number $($current2)" `
            -CurrentOperation $logFile.Name `
            -PercentComplete (($current2 / $total2) * 100)
        $sourceIpAddress = $entry.Split(" ")[0]
        $sourceName = $entry.Split(" ")[2]
        $matches = $entry | Select-String -Pattern "\[(.*?)\]" -AllMatches | ForEach-Object { $_.Matches }
        $timeStamp = $matches.Value.Trim('[]')
        $matches2 = $entry | Select-String -Pattern '"(.*?)"' -AllMatches | ForEach-Object { $_.Matches }
        $message = $matches2.Value.Trim('""')
        $replyCode = $entry.Split(" ")[-2..-1]

        $result += "$($sourceIpAddress);$($sourceName);$($timeStamp);$($message);$($replyCode)"
    }
}

$result >> result3.txt
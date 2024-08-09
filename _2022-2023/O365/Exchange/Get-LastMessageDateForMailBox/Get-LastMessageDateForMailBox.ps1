Connect-ExchangeOnline

$list = Get-Content -Path "C:\scirps\ExchangeOnline\Get-LastMessageDateForMailBox90Days\list.txt"
$batchRootFolder = "C:\scirps\ExchangeOnline\Get-LastMessageDateForMailBox90Days\batches"
$currentBatchFolder = New-Item -Name "$(Get-Date -Format 'ddMMyyyy_hhmmss')" -Path $batchRootFolder -ItemType Directory

$batchCount = 0
$dlCount = 0
$newBatch = $null
Write-Host "batchCount is $batchCount" -foregroundcolor yellow
Write-Host "dlCount is $dlCount" -foregroundcolor yellow
foreach ($dl in $list) {
    $dlCount++
    [array]$newBatch += $dl
    if ($dlCount -eq 100) {
        $batchCount++
        $newBatchFile = New-Item -Name "$(Get-Date -Format 'ddMMyyyyhhmmss')_batch$($batchCount).txt" -Path $currentBatchFolder.FullName
        $newBatch > $newBatchFile.FullName
        $newBatch = $null
        $dlCount = 0
    }
}

$batchFiles = Get-ChildItem -Path $currentBatchFolder.FullName
foreach ($file in $batchFiles) {
    $DLsToProcess = $null
    $reportTiltle = $file.Name.Replace('.txt', '')
    $DLs = Get-Content -Path $file.FullName
    foreach ($dl in $DLs) {
        [array]$DLsToProcess += ($dl -join '","')
    }

    $job = Start-HistoricalSearch `
        -StartDate $((Get-Date).AddDays(-90)) `
        -EndDate $(Get-Date) `
        -ReportTitle $reportTiltle `
        -RecipientAddress $DLsToProcess `
        -ReportType MessageTraceDetail `
        -Verbose

    Rename-Item -Path $file.FullName -NewName "$($file.FullName.Replace('.txt', ''))_$($job.JobId).txt"
    Start-Sleep -Seconds 20
}

# to check jobs' status
$batchFiles = Get-ChildItem -Path $currentBatchFolder.FullName
foreach ($batch in $batchFiles) {
    $id = $batch.Name.Split('_')[2].Replace(".txt", "")
    $status = (Get-HistoricalSearch -JobId $id).Status
    Write-Host "Batch name: $($batch.Name), batch status:$($status)"
}
# to cancel all jobs
foreach ($batch in $batchFiles) {
    $id = $batch.Name.Split('_')[2].Replace(".txt", "")
    Stop-HistoricalSearch -JobId $id -Verbose
}
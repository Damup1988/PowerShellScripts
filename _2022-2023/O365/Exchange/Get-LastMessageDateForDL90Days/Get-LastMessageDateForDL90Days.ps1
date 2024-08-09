Connect-ExchangeOnline

$rootPath = "C:\_bufer\_scripts\O365\Exchange\Get-LastMessageDateForDL90Days"
$list = Get-Content -Path "$rootPath\list.txt"
$batchRootFolder = "$rootPath\batches"
$currentBatchFolder = New-Item `
    -Name "$(Get-Date -Format 'ddMMyyyy_hhmmss')" `
    -Path $batchRootFolder -ItemType Directory

$batchCount = 0
$dlCount = 0
$newBatch = $null
foreach ($dl in $list) {
    $dlCount++
    [array]$newBatch += $dl
    if ($dlCount -eq 100) {
        $batchCount++
        $newBatchFile = New-Item `
            -Name "$(Get-Date ` -Format 'ddMMyyyyhhmmss')_batch$($batchCount).txt" `
            -Path $currentBatchFolder.FullName
        $newBatch > $newBatchFile.FullName
        $newBatch = $null
        $dlCount = 0
    }
}

#region receive jobs
# receive jobs
$batchFiles = Get-ChildItem -Path $currentBatchFolder.FullName | Where-Object {$_.Mode -eq "-a----"}
$receiveJobsFolder = New-Item -Name "Receive" -Path $currentBatchFolder.FullName -ItemType Directory
foreach ($file in $batchFiles) {
    $DLsToProcess = $null
    $reportTiltle = "$($file.Name.Replace('.txt', ''))_Receive"
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

    Copy-Item `
        -Path $file.FullName `
        -Destination "$($receiveJobsFolder.FullName)\$($file.Name.Replace('.txt', ''))_receive_$($job.JobId).txt"
    #Rename-Item -Path $file.FullName -NewName "$($file.FullName.Replace('.txt', ''))_$($job.JobId).txt"
    Start-Sleep -Seconds 10
}
#endregion

#region send jobs
# send jobs
$batchFiles = Get-ChildItem -Path $currentBatchFolder.FullName | Where-Object {$_.Mode -eq "-a----"}
$sendJobsFolder = New-Item -Name "Send" -Path $currentBatchFolder.FullName -ItemType Directory
foreach ($file in $batchFiles) {
    $DLsToProcess = $null
    $reportTiltle = "$($file.Name.Replace('.txt', ''))_Send"
    $DLs = Get-Content -Path $file.FullName
    foreach ($dl in $DLs) {
        [array]$DLsToProcess += ($dl -join '","')
    }

    $job = Start-HistoricalSearch `
        -StartDate $((Get-Date).AddDays(-90)) `
        -EndDate $(Get-Date) `
        -ReportTitle $reportTiltle `
        -SenderAddress $DLsToProcess `
        -ReportType MessageTraceDetail `
        -Verbose

    Copy-Item `
        -Path $file.FullName `
        -Destination "$($sendJobsFolder.FullName)\$($file.Name.Replace('.txt', ''))_send_$($job.JobId).txt"
    #Rename-Item -Path $file.FullName -NewName "$($file.FullName.Replace('.txt', ''))_$($job.JobId).txt"
    Start-Sleep -Seconds 10
}
#endregion

# to check jobs' status
$batchFiles = Get-ChildItem -Path $currentBatchFolder.FullName -Recurse `
    | Where-Object {$_.Mode -eq "-a----"} | Where-Object {$_.Name -like "*receive*" -or $_.Name -like "*send*"}
foreach ($batch in $batchFiles) {
    $id = $batch.Name.Split('_')[3].Replace(".txt", "")
    $status = (Get-HistoricalSearch -JobId $id).Status
    Write-Host "Batch name: $($batch.Name), batch status:$($status)"
}
# to cancel all jobs
foreach ($batch in $batchFiles) {
    $id = $batch.Name.Split('_')[3].Replace(".txt", "")
    Stop-HistoricalSearch -JobId $id -Verbose
}
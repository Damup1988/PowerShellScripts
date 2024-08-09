Connect-ExchangeOnline

$rootPath = "C:\_bufer\_scripts\O365\Exchange\Get-LastMessageDateForDL90Days"

$log = "$rootPath\log.txt"
"DL;LastReceiveMessageDate;LastSendMessageDate;AmountOfMembers;Owners;SendAsUsers;Batch" > "$rootPath\out.csv"
$dataFolderPath = "$rootPath\reports"
$dataFiles = Get-ChildItem -Path $dataFolderPath
$batchFiles = Get-ChildItem -Path "$rootPath\batches\16082023_102840" | Where-Object {$_.Mode -eq "-a----"}

$total = $batchFiles.count
$current = 0
foreach ($batch in $batchFiles) {
    $current++
    Write-Progress -Activity "Processing batches (total batches: $total)" -CurrentOperation $batch.Name -PercentComplete (($current / $total) * 100)

    #$batch = Get-ChildItem -Path "C:\_bufer\_scripts\O365\Exchange\Get-LastMessageDateForDL90Days\batches\16082023_102840\16082023102840_batch6.txt"

    $DLs = Get-Content -Path $batch.FullName
    $butchNumber = $batch.Name.Split("_")[1].Replace(".txt", "")

    $receiveReportPath = $($dataFiles | Where-Object {$_.Name.Split('_')[2] -eq $butchNumber -and $_.Name -like "*receive*"}).FullName
    $sendReportPath = $($dataFiles | Where-Object {$_.Name.Split('_')[2] -eq $butchNumber -and $_.Name -like "*send*"}).FullName

    if ($null -eq $receiveReportPath -and $null -eq $sendReportPath) {
        "No send and receive data for $($batch.Name)" >> $log
        continue        
    }
    if ($null -eq $receiveReportPath) {
        "No receive data for $($batch.Name)" >> $log
        $haveReceive = $false
    }
    else {
        $haveReceive = $true
        $receiveData = Import-Csv -Path $receiveReportPath -Encoding Unicode
    }
    if ($null -eq $sendReportPath) {
        "No send data for $($batch.Name)" >> $log
        $haveSend = $false
    }
    else {
        $haveSend = $true
        $sendData = Import-Csv -Path $sendReportPath -Encoding Unicode
    }

    $total2 = $DLs.count
    $current2 = 0
    foreach ($dl in $DLs) {
        $current2++
        Write-Progress -Activity "Processing DLs (total: $total2), batch: $($batch.Name)" -CurrentOperation $dl -PercentComplete (($current2 / $total2) * 100)

        $ownedBy = @()
        $sendAsUsers = @()

        $dlExists = $null -ne (Get-DistributionGroup -Identity $dl -ErrorAction SilentlyContinue)
        if (!$dlExists) {
            "$($dl);DL doesn't exist;DL doesn't exist;DL doesn't exist;DL doesn't exist;DL doesn't exist;$butchNumber" >> "$rootPath\out.txt"
            continue
        }
        else {
            $membersAmount = (Get-DistributionGroupMember -Identity $dl).name.count

            $owners = (Get-DistributionGroup -Identity $dl | Select-Object ManagedBy).ManagedBy
            if ($owners.count -eq 0) {
                $ownedBy = "NULL"
            }
            else {
                foreach ($owner in $owners) {
                    $ownedBy += $owner
                    $ownedBy += "|"
                }
            }

            $sendAs = (Get-EXORecipientPermission -Identity $dl | Select-Object Trustee).Trustee
            if ($sendAs.count -eq 0) {
                $sendAsUsers = "NULL"
            }
            else {
                foreach ($sendAsUser in $sendAs) {
                    $sendAsUsers += $sendAsUser
                    $sendAsUsers += "|"
                }
            }

            if ($haveReceive -and $haveSend) {
                $receiveDatesString = ($receiveData `
                    | Where-Object {$_.recipient_address -like "*$dl*"} `
                    | Select-Object date_time_utc).date_time_utc
                $sendDatesString = ($sendData `
                    | Where-Object {$_.recipient_address -like "*$dl*"} `
                    | Select-Object date_time_utc).date_time_utc
                if ($null -eq $receiveDatesString -and $null -eq $sendDatesString) {
                    "$($dl);NULL;NULL;$membersAmount;$ownedBy;$sendAsUsers;$butchNumber" >> "$rootPath\out.txt"
                }
                if ($null -ne $receiveDatesString -and $null -ne $sendDatesString) {
                    $datesReceiveDateTime = @()
                        foreach ($date in $receiveDatesString) {
                            $datesReceiveDateTime += [datetime]$date
                        }
                    $latestReceiveDate = $datesReceiveDateTime | Sort-Object | Select-Object -Last 1
                    $datesSendDateTime = @()
                        foreach ($date in $sendDatesString) {
                            $datesSendDateTime += [datetime]$date
                        }
                    $latestSendDate = $datesSendDateTime | Sort-Object | Select-Object -Last 1
                    "$dl;$latestReceiveDate;$latestSendDate;$membersAmount;$ownedBy;$sendAsUsers;$butchNumber" >> "$rootPath\out.txt"
                }
                if ($null -ne $receiveDatesString -and $null -eq $sendDatesString) {
                    $datesReceiveDateTime = @()
                        foreach ($date in $receiveDatesString) {
                            $datesReceiveDateTime += [datetime]$date
                        }
                    $latestReceiveDate = $datesReceiveDateTime | Sort-Object | Select-Object -Last 1
                    "$dl;$latestReceiveDate;NULL;$membersAmount;$ownedBy;$sendAsUsers;$butchNumber" >> "$rootPath\out.txt"
                }
                if ($null -eq $receiveDatesString -and $null -ne $sendDatesString) {
                    $datesSendDateTime = @()
                        foreach ($date in $sendDatesString) {
                            $datesSendDateTime += [datetime]$date
                        }
                    $latestSendDate = $datesSendDateTime | Sort-Object | Select-Object -Last 1
                    "$dl;NULL;$latestSendDate;$membersAmount;$ownedBy;$sendAsUsers;$butchNumber" >> "$rootPath\out.txt"
                }
            }
            if ($haveReceive -and !$haveSend) {
                $receiveDatesString = ($receiveData `
                    | Where-Object {$_.recipient_address -like "*$dl*"} `
                    | Select-Object date_time_utc).date_time_utc
                if ($null -eq $receiveDatesString) {
                    "$($dl);NULL;NULL;$membersAmount;$ownedBy;$sendAsUsers;$butchNumber" >> "$rootPath\out.txt"
                }
                else {
                    $datesReceiveDateTime = @()
                    foreach ($date in $receiveDatesString) {
                        $datesReceiveDateTime += [datetime]$date
                    }
                    $latestReceiveDate = $datesReceiveDateTime | Sort-Object | Select-Object -Last 1
                    "$($dl);$latestReceiveDate;NULL;$membersAmount;$ownedBy;$sendAsUsers;$butchNumber" >> "$rootPath\out.txt"
                }
            }
            if (!$haveReceive -and $haveSend) {
                $sendDatesString = ($sendData `
                    | Where-Object {$_.recipient_address -like "*$dl*"} `
                    | Select-Object date_time_utc).date_time_utc
                if ($null -eq $sendDatesString) {
                    "$($dl);NULL;NULL;$membersAmount;$ownedBy;$sendAsUsers;$butchNumber" >> "$rootPath\out.txt"
                }
                else {
                    $datesSendDateTime = @()
                    foreach ($date in $sendDatesString) {
                        $datesSendDateTime += [datetime]$date
                    }
                    $latestSendDate = $datesSendDateTime | Sort-Object | Select-Object -Last 1
                    "$($dl);NULL;$latestSendDate;$membersAmount;$ownedBy;$sendAsUsers;$butchNumber" >> "$rootPath\out.txt"
                }
            }
        }
    }
}
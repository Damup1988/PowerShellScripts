$logs = Get-Content -Path "C:\_bufer\_scripts\PowerShell\smtp-check\pfx_log_202_summer.txt"

$myData = @()

$count = $logs.Count
for ($i = 0; $i -lt $count; $i++) {
    if ($logs[$i] -like "*: connect from unknown*") {
        $pos = $logs[$i + 1].IndexOf("]: ")
        $left = $logs[$i + 1].Substring($pos + 3)
        $pos2 = $left.IndexOf(": ")
        $left
        $id = $left.Substring(0, $pos2)
        $myData += $id
    }
}

Write-Host "$($myData.Count)" -ForegroundColor Yellow

$myData2 = @()

$data_count = 0
foreach ($value in $myData) {
    $MyTable = New-Object System.Object
    if ($value.Length -lt 11) {
        $data_count++
        Write-Host "Doing $value - $data_count..." -ForegroundColor Yellow
        $MyTable | Add-Member -Type NoteProperty -Name "Id" -Value $value

        $str = $logs | Where-Object {$_.contains("$($value): client=unknown")}
        $regex = $str -match '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
        $ipAddress = $Matches[0]        
        $MyTable | Add-Member -Type NoteProperty -Name "IpAddress" -Value $ipAddress

        $from = $logs | Where-Object {$_.contains("$($value): from=<")}
        $pos = $from.IndexOf("from=<")
        $left = $from.Substring($pos + 6)
        $pos2 = $left.IndexOf(">,")
        $from = $left.Substring(0, $pos2)
        $MyTable | Add-Member -Type NoteProperty -Name "From" -Value $from

        $to = $logs | Where-Object {$_.contains("$($value): to=<")}
        $count = $to.Count
        $total_to = $null
        $counter = 0
        foreach ($var in $to) {
            $counter++
            $pos = $var.IndexOf("to=<")
            $left = $var.Substring($pos + 4)
            $pos2 = $left.IndexOf(".com>,")
            $curr_to = $left.Substring(0, $pos2 + 4)
            $total_to += $curr_to
            if ($counter -ne $count) {
                $total_to += ","
            }
        }
        $MyTable | Add-Member -Type NoteProperty -Name "To" -Value $total_to
    }
    $myData2 += $MyTable
}

$myData2 | Import-Csv -Delimiter ';' -LiteralPath "data.csv"
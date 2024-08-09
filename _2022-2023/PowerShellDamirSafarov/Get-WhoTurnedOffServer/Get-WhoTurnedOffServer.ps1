$servers = @()
$regexString = ""

foreach ($server in $servers) {
    $events = Invoke-Command `
        -ComputerName $server `
        -ScriptBlock {Get-EventLog -LogName System `
            | Where-Object {$_.eventid -eq 1074} `
            | Select-Object message}

        foreach ($event in $events) {
            $found = $event.Message -match $regexString
            if ($found) {
                $accName = $Matches[0]
                $accName
            }
        }
}
Start-Transcript -path "C:\_exchnageScripts\Remove-NonErpEmailsFromQueue\transcript.txt" -append

Get-Queue | Get-Message | ? {$_.recipient -ne "erp.notification@petrofac.com"} `
    | Remove-Message `
        -WithNDR $false `
        -Confirm:$false `
        -ErrorAction SilentlyContinue `
        -Verbose

Stop-Transcript
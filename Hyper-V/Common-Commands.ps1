Get-VM

Get-VM | Where-Object {$_.state -eq "Running"} | Stop-VM -TurnOff
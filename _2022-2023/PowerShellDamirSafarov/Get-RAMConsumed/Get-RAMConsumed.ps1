# list all the processes, RAM descending
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10

(Get-Process | Measure-Object WorkingSet -Sum).Sum / 1MB
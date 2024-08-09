# Cloud Datacenter - ff8ea09d-a6a9-482a-a209-58f43068b627

$rgs = Get-Content -Path "C:\_bufer\_scripts\Azure\Find-JobByID\rgs.txt"

foreach ($rg in $rgs) {
    $autAccs = Get-AzAutomationAccount -ResourceGroupName $rg

    foreach ($autAc in $autAccs) {
        Get-AzAutomationJob `
            -ResourceGroupName $rg `
            -AutomationAccountName $autAc.AutomationAccountName `
            -Id "b285a246-8a29-4115-b830-c56ec5c4a00a" `
            -Verbose `
            -ErrorAction SilentlyContinue
    }
}
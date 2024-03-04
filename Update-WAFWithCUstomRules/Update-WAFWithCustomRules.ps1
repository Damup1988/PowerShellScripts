# file to save all exclusions before add new
$backupFile = "C:\_bufer\_scripts\Azure\Update-WAFWithCUstomRules\backup.txt"

$subs = Get-Content -Path "C:\_bufer\_scripts\Azure\Update-WAFWithCUstomRules\subs.txt"
$allSubs = Get-AzSubscription | Where-Object {$subs -contains $_.Id}

# get all WAFs from all subs
$WAFs = @()
foreach ($id in $allSubs) {
    Select-AzSubscription -SubscriptionId $id
    $WAFs += Get-AzApplicationGatewayFirewallPolicy
}

# we need only WAFs that are enabled and in prevention mode
$enabledWAFs = @()
foreach ($waf in $WAFs) {
    $wafState = ($waf | Select-Object PolicySettings).PolicySettings.State
    $wafMode = ($waf | Select-Object PolicySettings).PolicySettings.Mode
    if ($wafState -eq "Enabled" -and $wafMode -eq "Prevention") {
        $enabledWAFs += $waf
    }
}

# create new rule
$ExclusionIPaddresses = @("xxx.xxx.xxx.xxx","xxx.xxx.xxx.xxx","xxx.xxx.xxx.xxx")
$variable = New-AzApplicationGatewayFirewallMatchVariable -VariableName RemoteAddr
$condition = New-AzApplicationGatewayFirewallCondition `
    -MatchVariable $variable `
    -Operator IPMatch `
    -MatchValue $ExclusionIPaddresses
$newRule = New-AzApplicationGatewayFirewallCustomRule `
    -Name "" `
    -Priority 77 `
    -RuleType MatchRule `
    -MatchCondition $condition `
    -Action Allow `
    -State Enabled

# add new rule to the existing rules
foreach ($waf in $enabledWAFs) {
    $currSub = Select-AzSubscription -SubscriptionId $waf.Id.Split('/')[2]
    $allCustomRules = (get-AzApplicationGatewayFirewallPolicy `
        -Name $waf.Name `
        -ResourceGroupName $waf.ResourceGroupName).CustomRules
    write-host "$($waf.Name)" -foregroundcolor yellow
    $allCustomRules
    $waf.Name >> $backupFile
    $allCustomRules | Format-List >> $backupFile
    #$allCustomRules += $newRule
    #Set-AzApplicationGatewayFirewallPolicy -Name $waf.Name -ResourceGroupName $waf.ResourceGroupName -CustomRule $allCustomRules
}
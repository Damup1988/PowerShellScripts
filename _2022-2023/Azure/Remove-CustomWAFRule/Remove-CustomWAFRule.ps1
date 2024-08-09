$subs = Get-Content -Path .\subs.txt

$WAFs = @()
foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub
    $WAFs += Get-AzApplicationGatewayFirewallPolicy
}

$enabledWAFs = @()
foreach ($waf in $WAFs) {
    $wafState = ($waf | select PolicySettings).PolicySettings.State
    $wafMode = ($waf | select PolicySettings).PolicySettings.Mode
    if ($wafState -eq "Enabled" -and $wafMode -eq "Prevention") {
        $enabledWAFs += $waf
    }
}

foreach ($waf in $enabledWAFs) {
    $currSub = Select-AzSubscription -SubscriptionId $waf.Id.Split('/')[2]
    az network application-gateway waf-policy custom-rule delete -g $waf.ResourceGroupName --policy-name $waf.Name -n "CHG0049219"
}
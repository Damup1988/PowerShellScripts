$workspaceId = "92216615-5057-4948-ad0f-558df37f3156"
$workspaceKey = "ApeXpPL6d1hkE40Eki7fgU9f/gsIqVmiU6nX0S8NFj2MDt3dDQci5OpNU9rcfksAPQHtkVI1FwsD/3V1mmmU8Q=="
$proxyurl = '10.142.1.11:3128'
$SharjahMG = 'SCOMPRDDXBUAE'
$SharjahServer = 'SCO001PRDDXBUAE.ds.petrofac.local'
$AzureMG = 'SCOMPRDEUNAZR'
$AzureServer = 'SCM002PRDEUNAZR.ds.petrofac.local'
$SCOMPort = 5723 

$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$exitcode = 0

$mmaCloudWorkspace = $mma.GetCloudWorkspace($workspaceId)

$mmaSharjahMG = $mma.GetManagementGroup($SharjahMG)
$mmaAzureMG = $mma.GetManagementGroup($AzureMG)


$fSetWorkspace = 1
$fSetProxy = 1
$fSetSharjah = 1
$fSetAzure = 1

if($mmaSharjahMG){
    $fSetSharjah = 0
    Write-Output "$SharjahMG exists on $env:COMPUTERNAME"
}else {
    Write-Warning "$SharjahMG not exists on $env:COMPUTERNAME"
}

if($mmaAzureMG){
    $fSetAzure = 0
    Write-Output "$AzureMG exists on $env:COMPUTERNAME"
}else {
    Write-Warning "$AzureMG not exists on $env:COMPUTERNAME"
}

<#if(($mma.proxyUrl -eq $proxyurl) -and (-not $mma.proxyUsername)){
    Write-Output "Proxy is set up properly on $env:COMPUTERNAME"
    $fSetProxy = 0
}else {
    Write-Warning "Proxy is set up wrong on $env:COMPUTERNAME"
}#>

if($mmaCloudWorkspace){
    $fSetWorkspace = 0
    if($mmaCloudWorkspace.ConnectionStatus -eq 0){
        Write-Output "ATP is properly set up and running on $env:COMPUTERNAME"
    }else {
        $connectionStatusText = $mmaCloudWorkspace.ConnectionStatusText
        Write-Warning "ATP exists but something is wrong on $env:COMPUTERNAME. The ConnectionStatusText is $connectionStatusText"   
    }
}else {
  Write-Warning "No ATP record is found on $env:COMPUTERNAME" 
}


if($fSetSharjah){
    $mma.AddManagementGroup($SharjahMG, $SharjahServer, $SCOMPort)
    $exitcode = $exitcode + 8; 
    Write-Output "Setting up Sharjah management group"
}
if($fSetAzure){
    $mma.AddManagementGroup($AzureMG, $AzureServer, $SCOMPort)
    $exitcode = $exitcode + 4; 
    Write-Output "Setting up Azure management group"
}
if($fSetWorkspace){
    $mma.AddCloudWorkspace($workspaceId, $workspaceKey)
    $exitcode = $exitcode + 2; 
    Write-Output "Adding cloud workspace (ATP)"      
}
<#if($fSetProxy){
    $mma.SetProxyUrl($proxyurl)
    $mma.SetProxyCredentials('','')
    $exitcode = $exitcode + 1;   
    Write-Output "Fixing proxy settings"      
}#>
if(($fSetWorkSpace + $fSetProxy + $fSetSharjah + $fSetAzure) -gt 0){
    $mma.ReloadConfiguration()
    Write-Output "Restarting Microsoft Monitoring Agent"      
} 

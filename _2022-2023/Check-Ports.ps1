#lic servers
$licServers = @("LIC006PRDSASAZR", "LIC007PRDSASAZR", "LIC008PRDSASAZR")
$ports = @(744, 4545, 4546, 59474, 27001)
foreach ($server in $licServers) {
    foreach ($port in $ports) {
        $check = tnc $server -p $port
        if (!$check.TcpTestSucceeded) {
            Write-Host "$server is not available by $port" -ForegroundColor Red
        }
        else {
            Write-Host "$server is available by $port" -ForegroundColor Yellow
        }
    }
}

#http and https
$myHosts = @("autodesk.com", "Bentley.com", "signalr.net")
$ports = @(80, 443)
foreach ($url in $myHosts) {
    foreach ($port in $ports) {
        $check = tnc $url -p $port
        if (!$check.TcpTestSucceeded) {
            Write-Host "$url is not available by $port" -ForegroundColor Red
        }
        else {
            Write-Host "($url is available by $port" -ForegroundColor Yellow
        }
    }
}

#fileStorages
$storages = @(
    "saeunprdlzavd01fnc.privatelink.file.core.windows.net",
    "saeunprdlzavd02fnc.privatelink.file.core.windows.net",
    "strgenggappprdsasazr.file.core.windows.net",
    "FIL023AAASHJUAE",
    "APP100PRDEUNAZR")
$ports = @(139, 445)
foreach ($fs in $storages) {
    foreach ($port in $ports) {
        $check = tnc $fs -p $port
        if (!$check.TcpTestSucceeded) {
            Write-Host "$fs is not available by $port" -ForegroundColor Red
        }
        else {
            Write-Host "$fs is available by $port" -ForegroundColor Yellow
        }
    }    
}

#strgenggappprdsasazr.file.core.windows.net by 443
$check = tnc strgenggappprdsasazr.file.core.windows.net -p 443
if (!$check.TcpTestSucceeded) {
    Write-Host "strgenggappprdsasazr.file.core.windows.net is not available by 443" -ForegroundColor Red
}
else {
    Write-Host "strgenggappprdsasazr.file.core.windows.net is available by 443" -ForegroundColor Yellow
}
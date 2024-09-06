$ports = @(135,389,636,3268,3269,53,88,445)
$servers = @("")
$result = "C:\Users\dsafarov-fa\Documents\result.txt"

foreach ($s in $servers) {
    foreach ($p in $ports) {
        Test-NetConnection $s -Port $p
        if ((Test-NetConnection $s -Port $p).TcpTestSucceeded) {
            Write-Host "$s is available via $p" -ForegroundColor Yellow
            "$s;$p;True" >> $result
        }
        else {
            Write-Host "$s is not available via $p" -ForegroundColor Red
            "$s;$p;False" >> $result
        }
    }
}
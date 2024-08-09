$creds = Get-Credential

$connectTestResult = Test-NetConnection -ComputerName sa01sharednetdrive.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Mount the drive
    New-PSDrive -Name J -PSProvider FileSystem -Root "\\sa01sharednetdrive.file.core.windows.net\sa01sharedfolder001" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

$connectTestResult = Test-NetConnection -ComputerName sa001sharedfolders.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Mount the drive
    New-PSDrive -Credential $creds -Name J -PSProvider FileSystem -Root "\\sa001sharedfolders.file.core.windows.net\sa001sharedfolder001" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
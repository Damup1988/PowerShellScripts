# Trim() - leading and trailing
# TrimEnd() - trailing
# TrimStart() - leading

$str1 = "damir.safarov@petrofac.com"
$str2 = "damir.safarov@Petrofac.com"
$str3 = "damir.safarov@Petrofac.Com"

Write-Host "Trim for damir.safarov@petrofac.com: $($str1.ToLower().Trim("@petrofac.com"))" -ForegroundColor Yellow
Write-Host "Trim for damir.safarov@Petrofac.com: $($str2.ToLower().Trim("@petrofac.com"))" -ForegroundColor Yellow
Write-Host "Trim for damir.safarov@Petrofac.Com: $($str3.ToLower().Trim("@petrofac.com"))" -ForegroundColor Yellow
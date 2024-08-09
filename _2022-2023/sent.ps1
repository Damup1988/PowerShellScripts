$smtpServer='petrofac-com.mail.protection.outlook.com'
$from='oleksiy.oleshkevych@petrofac.com'
$textEncoding = [System.Text.Encoding]::UTF8
$emailaddress = 'oleksiy.oleshkevych@petrofac.com'
$cc = 'damir.safarov@petrofac.com'
Send-Mailmessage `
    -smtpServer $smtpServer `
    -Port 25 `
    -from $from `
    -to $emailaddress `
    -subject "test1" `
    -body "tst" `
    -bodyasHTML `
    -priority High `
    -Encoding $textEncoding `
    -ErrorAction Stop
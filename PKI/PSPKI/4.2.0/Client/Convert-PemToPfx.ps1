﻿function Convert-PemToPfx {
<#
.ExternalHelp PSPKI.Help.xml
#>
[OutputType('[System.Security.Cryptography.X509Certificates.X509Certificate2]')]
[CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('CertificatePath', 'CertPath')]
        [string]$InputPath,
        [string]$KeyPath,
        [string]$OutputPath,
        [SysadminsLV.PKI.Cryptography.X509Certificates.X509KeySpecFlags]$KeySpec = "AT_KEYEXCHANGE",
        [Security.SecureString]$Password,
        [string]$ProviderName = "Microsoft Software Key Storage Provider",
        [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "CurrentUser",
        [switch]$Install
    )
    if ($PSBoundParameters["Verbose"]) {$VerbosePreference = "continue"}
    if ($PSBoundParameters["Debug"]) {$DebugPreference = "continue"}
    $ErrorActionPreference = "Stop"

    # PSCore needs extra assembly import
    if ($PsIsCore) {
        Add-Type -AssemblyName "System.Security.Cryptography.X509Certificates"
    }

    # global variables
    Write-Verbose "Determining key storage flags..."
    $KeyStorageFlags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    if ($Install) {
        if ($StoreLocation -eq "CurrentUser") {
            $KeyStorageFlags = $KeyStorageFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet
        } else {
            $KeyStorageFlags = $KeyStorageFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet
        }
    } else {
        $KeyStorageFlags = $KeyStorageFlags -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
    }
    Write-Verbose "Resulting storage flags: $KeyStorageFlags"

    $script:AlgFamily = ""
    [System.Collections.Generic.List[object]]$Disposables = @()

    # returns: X509Certificate2
    function __extractCert([string]$Text) {
        Write-Verbose "Reading certificate.."
        if ($Text -match "(?msx).*-{5}BEGIN\sCERTIFICATE-{5}(.+)-{5}END\sCERTIFICATE-{5}") {
            $CertRawData = [Convert]::FromBase64String($matches[1])
            $Cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList (,$CertRawData)
            Write-Verbose "Public key algorithm: $($Cert.PublicKey.Oid.FriendlyName) ($($Cert.PublicKey.Oid.Value))"
            switch ($Cert.PublicKey.Oid.Value) {
                $([SysadminsLV.PKI.Cryptography.AlgorithmOid]::RSA) { $script:AlgFamily = "RSA" }
                $([SysadminsLV.PKI.Cryptography.AlgorithmOid]::ECC) { $script:AlgFamily = "ECC" }
            }

            $Cert
        } else {
            throw "Missing certificate file."
        }
    }
    # returns: AsymmetricKey (RSACng or ECDsaCng)
    function __extractPrivateKey([string]$Text) {
        Write-Verbose "Reading private key..."
        $bin = if ($Text -match "(?msx).*-{5}BEGIN\sPRIVATE\sKEY-{5}(.+)-{5}END\sPRIVATE\sKEY-{5}") {
            Write-Verbose "Found private key in PKCS#8 format."
            [convert]::FromBase64String($matches[1])
        } elseif ($Text -match "(?msx).*-{5}BEGIN\sRSA\sPRIVATE\sKEY-{5}(.+)-{5}END\sRSA\sPRIVATE\sKEY-{5}") {
            Write-Verbose "Found RSA private key in PKCS#1 format."
            [convert]::FromBase64String($matches[1])
        }  else {
            throw "The data is invalid."
        }
        if ($AlgFamily -eq "RSA") {
            Write-Verbose "Converting RSA PKCS#1 to PKCS#8..."
            # RSA can be in PKCS#1 format, which is not supported by CngKey.
            $rsa = New-Object SysadminsLV.PKI.Cryptography.RsaPrivateKey (,$bin)
            $bin = $rsa.Export("Pkcs8")
            $rsa.Dispose()
        }

        Write-Verbose "Using provider: $ProviderName"
        $prov = [System.Security.Cryptography.CngProvider]::new($ProviderName)
        $blobType = [System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob
        # make it exportable
        $cngProp = New-Object System.Security.Cryptography.CngProperty("Export Policy", [BitConverter]::GetBytes(3), "None")
        $cng = [System.Security.Cryptography.CngKey]::Import($bin, $blobType, $prov)
        $Disposables.Add($cng)
        $cng.SetProperty($cngProp)

        switch ($AlgFamily) {
            "RSA" {
                New-Object System.Security.Cryptography.RSACng $cng
            }
            "ECC" {
                New-Object System.Security.Cryptography.ECDsaCng $cng
                
            }
            default {
                throw "Specified algorithm is not supported"
            }
        }
    }
    # returns: X509Certificate2 with associated private key
    function __associatePrivateKey($Cert, $AsymmetricKey) {
        Write-Verbose "Merging public certificate with private key..."
        switch ($AlgFamily) {
            "RSA" {
                if ($csp.IsLegacy) {
                    $NewCert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList (,$Cert.RawData)
                    $cspParams = New-Object System.Security.Cryptography.CspParameters $csp.Type, $ProviderName, ("pspki-" + [guid]::NewGuid())
                    $cspParams.KeyNumber = [int]$KeySpec
                    if ($Install) {
                        if ($StoreLocation -eq "LocalMachine") {
                            $cspParams.Flags = 1
                        }
                    } else {
                        #$cspParams.Flags = 128
                    }
                    $legacyRsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider $cspParams
                    $legacyRsa.ImportParameters($AsymmetricKey.ExportParameters($true))
                    $NewCert.PrivateKey = $legacyRsa

                    $NewCert
                } else {
                    [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::CopyWithPrivateKey($Cert, $AsymmetricKey)
                }
            }
            "ECC" {[System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::CopyWithPrivateKey($Cert, $AsymmetricKey)}
        }
        Write-Verbose "Public certificate and private key are successfully merged."
    }

    function __duplicateCertWithKey($CertWithKey) {
        $PfxBytes = $CertWithKey.Export("pfx")
        New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $PfxBytes, "", $KeyStorageFlags
    }
    function __installCert($CertWithKey) {
        if (!$Install) {
            $CertWithKey
            return
        }

        Write-Verbose "Installing certificate to certificate store: $StoreLocation"
        # $CertWithKey cert has ephemeral key which cannot be installed into cert store as is.
        # so export it into PFX in memory and re-import back with storage flags
        $NewCert = __duplicateCertWithKey $CertWithKey
        # dispose ephemeral cert received from params, we have a persisted cert to return
        $CertWithKey.Dispose()

        $store = New-Object Security.Cryptography.X509Certificates.X509Store "my", $StoreLocation
        $store.Open("ReadWrite")
        $Disposables.Add($store)
        $store.Add($NewCert)
        $store.Close()
        Write-Verbose "Certificate is installed."
        # dispose this temporary cert
        $NewCert
    }
    function __exportPfx($CertWithKey) {
        if ([string]::IsNullOrWhiteSpace($OutputPath)) {
            return
        }
        Write-Verbose "Saving PFX to a file: $OutputPath"
        if (!$Password) {
            $Password = Read-Host -Prompt "Enter PFX password" -AsSecureString
        }
        $pfxBytes = $CertWithKey.Export("pfx", $Password)
        Export-Binary $OutputPath $pfxBytes
        Write-Verbose "PFX is saved."
    }

    # Determine CSP
    $csp = Get-CryptographicServiceProvider -Name $ProviderName
    if (!$csp) {
        throw "Specified provider name is invalid."
    }

    # parse content
    $Text = Get-Content -Path $InputPath -Raw -ErrorAction Stop
    Write-Debug "Extracting certificate information..."
    $Cert = __extractCert $Text
    if ($KeyPath) {
        $Text = Get-Content -Path $KeyPath -Raw -ErrorAction Stop
    }
    $PrivateKey = __extractPrivateKey $Text
    $Disposables.Add($PrivateKey)

    $PfxCert = __associatePrivateKey $Cert $PrivateKey
    __exportPfx $PfxCert
    $PfxCert = __installCert $PfxCert
    # release unmanaged resources
    $Disposables | %{$_.Dispose()}

    $PfxCert
}
# SIG # Begin signature block
# MIIxEQYJKoZIhvcNAQcCoIIxAjCCMP4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCcuch2oPSDeNbh
# ASduY8N18YyXwEThMXZLjtuS4vn0EKCCFgowggQyMIIDGqADAgECAgEBMA0GCSqG
# SIb3DQEBBQUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQIDBJHcmVhdGVyIE1hbmNo
# ZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoMEUNvbW9kbyBDQSBMaW1p
# dGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2VydmljZXMwHhcNMDQwMTAx
# MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFD
# b21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZp
# Y2VzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvkCd9G7h6naHHE1F
# RI6+RsiDBp3BKv4YH47kAvrzq11QihYxC5oG0MVwIs1JLVRjzLZuaEYLU+rLTCTA
# vHJO6vEVrvRUmhIKw3qyM2Di2olV8yJY897cz++DhqKMlE+faPKYkEaEJ8d2v+PM
# NSyLXgdkZYLASLCokflhn3YgUKiRx2a163hiA1bwihoT6jGjHqCZ/Tj29icyWG8H
# 9Wu4+xQrr7eqzNZjX3OM2gWZqDioyxd4NlGs6Z70eDqNzw/ZQuKYDKsvnw4B3u+f
# mUnxLd+sdE0bmLVHxeUp0fmQGMdinL6DxyZ7Poolx8DdneY1aBAgnY/Y3tLDhJwN
# XugvyQIDAQABo4HAMIG9MB0GA1UdDgQWBBSgEQojPpbxB+zirynvgqV/0DCktDAO
# BgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zB7BgNVHR8EdDByMDigNqA0
# hjJodHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2Vz
# LmNybDA2oDSgMoYwaHR0cDovL2NybC5jb21vZG8ubmV0L0FBQUNlcnRpZmljYXRl
# U2VydmljZXMuY3JsMA0GCSqGSIb3DQEBBQUAA4IBAQAIVvwC8Jvo/6T61nvGRIDO
# T8TF9gBYzKa2vBRJaAR26ObuXewCD2DWjVAYTyZOAePmsKXuv7x0VEG//fwSuMdP
# WvSJYAV/YLcFSvP28cK/xLl0hrYtfWvM0vNG3S/G4GrDwzQDLH2W3VrCDqcKmcEF
# i6sML/NcOs9sN1UJh95TQGxY7/y2q2VuBPYb3DzgWhXGntnxWUgwIWUDbOzpIXPs
# mwOh4DetoBUYj/q6As6nLKkQEyzU5QgmqyKXYPiQXnTUoppTvfKpaOCibsLXbLGj
# D56/62jnVvKu8uMrODoJgbVrhde+Le0/GreyY+L1YiyC1GoAQVDxOYOflek2lphu
# MIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0BAQwFADB7
# MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UE
# AwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTIxMDUyNTAwMDAwMFoXDTI4
# MTIzMTIzNTk1OVowVjELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGlt
# aXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5nIFJvb3Qg
# UjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjeeUEiIEJHQu/xYj
# ApKKtq42haxH1CORKz7cfeIxoFFvrISR41KKteKW3tCHYySJiv/vEpM7fbu2ir29
# BX8nm2tl06UMabG8STma8W1uquSggyfamg0rUOlLW7O4ZDakfko9qXGrYbNzszwL
# DO/bM1flvjQ345cbXf0fEj2CA3bm+z9m0pQxafptszSswXp43JJQ8mTHqi0Eq8Nq
# 6uAvp6fcbtfo/9ohq0C/ue4NnsbZnpnvxt4fqQx2sycgoda6/YDnAdLv64IplXCN
# /7sVz/7RDzaiLk8ykHRGa0c1E3cFM09jLrgt4b9lpwRrGNhx+swI8m2JmRCxrds+
# LOSqGLDGBwF1Z95t6WNjHjZ/aYm+qkU+blpfj6Fby50whjDoA7NAxg0POM1nqFOI
# +rgwZfpvx+cdsYN0aT6sxGg7seZnM5q2COCABUhA7vaCZEao9XOwBpXybGWfv1Vb
# HJxXGsd4RnxwqpQbghesh+m2yQ6BHEDWFhcp/FycGCvqRfXvvdVnTyheBe6QTHrn
# xvTQ/PrNPjJGEyA2igTqt6oHRpwNkzoJZplYXCmjuQymMDg80EY2NXycuu7D1fkK
# dvp+BRtAypI16dV60bV/AK6pkKrFfwGcELEW/MxuGNxvYv6mUKe4e7idFT/+IAx1
# yCJaE5UZkADpGtXChvHjjuxf9OUCAwEAAaOCARIwggEOMB8GA1UdIwQYMBaAFKAR
# CiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQy65Ka/zWWSC8oQEJwIDaRXBeF
# 5jAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUEDDAKBggr
# BgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmljYXRlU2Vy
# dmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQASv6Hvi3SamES4aUa1
# qyQKDKSKZ7g6gb9Fin1SB6iNH04hhTmja14tIIa/ELiueTtTzbT72ES+BtlcY2fU
# QBaHRIZyKtYyFfUSg8L54V0RQGf2QidyxSPiAjgaTCDi2wH3zUZPJqJ8ZsBRNraJ
# AlTH/Fj7bADu/pimLpWhDFMpH2/YGaZPnvesCepdgsaLr4CnvYFIUoQx2jLsFeSm
# TD1sOXPUC4U5IOCFGmjhp0g4qdE2JXfBjRkWxYhMZn0vY86Y6GnfrDyoXZ3JHFuu
# 2PMvdM+4fvbXg50RlmKarkUT2n/cR/vfw1Kf5gZV6Z2M8jpiUbzsJA8p1FiAhORF
# e1rYMIIGGjCCBAKgAwIBAgIQYh1tDFIBnjuQeRUgiSEcCjANBgkqhkiG9w0BAQwF
# ADBWMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYD
# VQQDEyRTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwHhcNMjEw
# MzIyMDAwMDAwWhcNMzYwMzIxMjM1OTU5WjBUMQswCQYDVQQGEwJHQjEYMBYGA1UE
# ChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2Rl
# IFNpZ25pbmcgQ0EgUjM2MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA
# myudU/o1P45gBkNqwM/1f/bIU1MYyM7TbH78WAeVF3llMwsRHgBGRmxDeEDIArCS
# 2VCoVk4Y/8j6stIkmYV5Gej4NgNjVQ4BYoDjGMwdjioXan1hlaGFt4Wk9vT0k2oW
# JMJjL9G//N523hAm4jF4UjrW2pvv9+hdPX8tbbAfI3v0VdJiJPFy/7XwiunD7mBx
# NtecM6ytIdUlh08T2z7mJEXZD9OWcJkZk5wDuf2q52PN43jc4T9OkoXZ0arWZVef
# fvMr/iiIROSCzKoDmWABDRzV/UiQ5vqsaeFaqQdzFf4ed8peNWh1OaZXnYvZQgWx
# /SXiJDRSAolRzZEZquE6cbcH747FHncs/Kzcn0Ccv2jrOW+LPmnOyB+tAfiWu01T
# PhCr9VrkxsHC5qFNxaThTG5j4/Kc+ODD2dX/fmBECELcvzUHf9shoFvrn35XGf2R
# PaNTO2uSZ6n9otv7jElspkfK9qEATHZcodp+R4q2OIypxR//YEb3fkDn3UayWW9b
# AgMBAAGjggFkMIIBYDAfBgNVHSMEGDAWgBQy65Ka/zWWSC8oQEJwIDaRXBeF5jAd
# BgNVHQ4EFgQUDyrLIIcouOxvSK4rVKYpqhekzQwwDgYDVR0PAQH/BAQDAgGGMBIG
# A1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwGwYDVR0gBBQw
# EjAGBgRVHSAAMAgGBmeBDAEEATBLBgNVHR8ERDBCMECgPqA8hjpodHRwOi8vY3Js
# LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ1Jvb3RSNDYuY3Js
# MHsGCCsGAQUFBwEBBG8wbTBGBggrBgEFBQcwAoY6aHR0cDovL2NydC5zZWN0aWdv
# LmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdSb290UjQ2LnA3YzAjBggrBgEF
# BQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEMBQADggIB
# AAb/guF3YzZue6EVIJsT/wT+mHVEYcNWlXHRkT+FoetAQLHI1uBy/YXKZDk8+Y1L
# oNqHrp22AKMGxQtgCivnDHFyAQ9GXTmlk7MjcgQbDCx6mn7yIawsppWkvfPkKaAQ
# siqaT9DnMWBHVNIabGqgQSGTrQWo43MOfsPynhbz2Hyxf5XWKZpRvr3dMapandPf
# YgoZ8iDL2OR3sYztgJrbG6VZ9DoTXFm1g0Rf97Aaen1l4c+w3DC+IkwFkvjFV3jS
# 49ZSc4lShKK6BrPTJYs4NG1DGzmpToTnwoqZ8fAmi2XlZnuchC4NPSZaPATHvNIz
# t+z1PHo35D/f7j2pO1S8BCysQDHCbM5Mnomnq5aYcKCsdbh0czchOm8bkinLrYrK
# pii+Tk7pwL7TjRKLXkomm5D1Umds++pip8wH2cQpf93at3VDcOK4N7EwoIJB0kak
# 6pSzEu4I64U6gZs7tS/dGNSljf2OSSnRr7KWzq03zl8l75jy+hOds9TWSenLbjBQ
# UGR96cFr6lEUfAIEHVC1L68Y1GGxx4/eRI82ut83axHMViw1+sVpbPxg51Tbnio1
# lB93079WPFnYaOvfGAA0e0zcfF/M9gXr+korwQTh2Prqooq2bYNMvUoUKD85gnJ+
# t0smrWrb8dee2CvYZXD5laGtaAxOfy/VKNmwuWuAh9kcMIIGPzCCBKegAwIBAgIQ
# Efd03RltdNDaAqLltlkfXzANBgkqhkiG9w0BAQwFADBUMQswCQYDVQQGEwJHQjEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1Ymxp
# YyBDb2RlIFNpZ25pbmcgQ0EgUjM2MB4XDTIzMDIyMDAwMDAwMFoXDTI0MDIyMDIz
# NTk1OVowVjELMAkGA1UEBhMCVVMxDzANBgNVBAgMBk9yZWdvbjEaMBgGA1UECgwR
# UEtJIFNvbHV0aW9ucyBMTEMxGjAYBgNVBAMMEVBLSSBTb2x1dGlvbnMgTExDMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyLR2hd5LzHUR23XqbjZlPbnJ
# bUFRc+PV66v8W0Bbm+wp/n9wrpaBoz7PzEPvlGrcSVp7nBwZ+yAlZwcTySz7PwSV
# 8qAfQ7AoC0hYIYvKbwprJWjTjWdVWbxLvIkPvUMe/3EBSzFywrjuOwdB86SZ4+V8
# d0MB6mG69sVTUTtUK6sW2K1/nzhZNCYbLDhof88Ciq8TO7DGm7lOpX5GtBpYwnrV
# coyndXgyAyEa6otHJPMYjtYVdMq8zw50l5WyulDCaSoQp8fsRMqppaeU3hguYjxf
# CV6I6MYKpLxowXyHL8l7ULKcHujZCerYsHEJ6Gnh0wWFoLHPZ3w6huSaJhLP+vd2
# 6iDWsnGlRcObDV6SRYsHJgN1n2HtMZauzmavQuyfFmUZhMmI6jYkFMwqN2WgdXT8
# dQECTOzOLaiO7I5XgwIvJOcckRWopDZm43ppGA33GdXY8vtVpk2EL+tPdPtkohD5
# W5+j5PoZnSQWW6L0f5k0tq0v2d8w5hAc3/E0WbOAXepFwqFykj0JuwE8Rz87Ss9Y
# 05vKGCe88AEjtYp0SfarzvfCkcOUYgaXska3RtSxtAO2dWB9bWrzPRi2tAKVkV7x
# CTEmKAof8wVnhpvkCJixxmS1mCX6UqlGxq3rUIWDtBkGJ5Il5TUjqXjIZptqTm7p
# gQgymaatGa0X65Ehr98CAwEAAaOCAYkwggGFMB8GA1UdIwQYMBaAFA8qyyCHKLjs
# b0iuK1SmKaoXpM0MMB0GA1UdDgQWBBTrDyPMgDt8WGUsl4kbs2rIibZp2zAOBgNV
# HQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzBK
# BgNVHSAEQzBBMDUGDCsGAQQBsjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczov
# L3NlY3RpZ28uY29tL0NQUzAIBgZngQwBBAEwSQYDVR0fBEIwQDA+oDygOoY4aHR0
# cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIz
# Ni5jcmwweQYIKwYBBQUHAQEEbTBrMEQGCCsGAQUFBzAChjhodHRwOi8vY3J0LnNl
# Y3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNydDAjBggr
# BgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEMBQAD
# ggGBAFmUMcCyDB1HtgACnyKs2mAviXDRve2HzxHCDWTYq9xVBFn+PCvYv1wTcWaA
# CW73yBnuu9MV831ltAqeqGqcApbUveFQi2lh7SX8ph6BNTm4PBMdbXfNJDrzig4F
# odjtIL+4LlIfZcLM2VsHG6pYGvPolR2rrD87CPweVed66gvAr6taK6VAF/A3Ivhw
# GKNT2k4stMco/MqyvuP0wddmSWx3gbIZcJz51jJuVk3okboB9oVCMP3jsgaaS9RE
# TErbVYnZEbEsBCh3Mc5fC5GIysI/mYwx+LFqnVYT1zy16sNCMW03pllrEccethlB
# 50r0fOpi0HcBfffgJ3ysZZBV3WZ95woZff+2PlluNV/spyN21B0kVjjvVyskFXG+
# ZRJis2C9jPwfCHKB9SxTFCdBKVInPGBOD7p1tDpmrr0EIEpTmM3kmiwgffY/MOrB
# MJf5beA3sGsx1U6/gZFvEGH9bM+Yt5AEQ7CX+dgUFsXPUUAi9OQ8yVXu8ufQQue9
# 9fxAfjGCGl0wghpZAgEBMGgwVDELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3Rp
# Z28gTGltaXRlZDErMCkGA1UEAxMiU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5n
# IENBIFIzNgIQEfd03RltdNDaAqLltlkfXzANBglghkgBZQMEAgEFAKCBhDAYBgor
# BgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDn
# nLmkwl/Ur9v9gtFCPCw1F1S4kFTelAYOOZ8XogyGGjANBgkqhkiG9w0BAQEFAASC
# AgAZYZWyfFlQVXR06anPyP8O8YSoORt2GEIXrsug5cIu6gmi4TbjzxO1sOZaYTHh
# BY/MeNuokz9bd/HHjT6cUSOD4udCDmXkDd/F/+vH0frB1nbqC8jhykQRgsScN/xh
# cqF7KdbSBg91/XGkjvq6k6SjcNqYhTL3OBxCPe42f4YcORq6dkTqNfPHmcWSjQwh
# Y02EEtCjiidykpX8Csl0hR5YIs2Tdi0gi3cJs46dOBZm51RBLIh4VmjWncIs63Qz
# 4AxLFEZxNJ0F3c4YofolTd0yV+sGHJJhxz5AwsxDTDiFVLGAbZWtqJhEqOrrmhzC
# xMFBF17E9ect18Lv9ta9igcu8U/cQQlSiIQD2lOl4wZdnGIeMj1gbRba8+Wh0zud
# Oq8rhVsUO6LFV/xB6eLmaSoMM212r10ZcWjScD176GY8WqkYnIMFpcaEOQOvG72z
# f2SKobBbJJiL9wFtsPxmbT1nbDCcKATCzgMI3MX8tyxEIjhja5+Ba7FVsj1C8IpM
# 7uybPTsTopfEWgo2PouQSwnp6WGnFKcUamKYAPufXoNv8yy9RIV1K9O8Peiv4e70
# NNMXKQYCpYjJWp67vetbq+y8ZOntqFFd+v+D0yaSEhKnk+szpRELkVOXACJd6S4n
# GX41HS3YANPY3o3ZpmDrYhqEU/CBNaXv8ArjBYueExjJJaGCFz8wghc7BgorBgEE
# AYI3AwMBMYIXKzCCFycGCSqGSIb3DQEHAqCCFxgwghcUAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCDsdgsSAIQ+ZAPbO3ke+VingP7JdfwbVaGgQTQCIjJbxgIQOfEp
# /WTvBwOlhIKFObOcXxgPMjAyNDAxMTgwOTU3MjhaoIITCTCCBsIwggSqoAMCAQIC
# EAVEr/OUnQg5pr/bP1/lYRYwDQYJKoZIhvcNAQELBQAwYzELMAkGA1UEBhMCVVMx
# FzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVz
# dGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTAeFw0yMzA3MTQw
# MDAwMDBaFw0zNDEwMTMyMzU5NTlaMEgxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjEgMB4GA1UEAxMXRGlnaUNlcnQgVGltZXN0YW1wIDIwMjMw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCjU0WHHYOOW6w+VLMj4M+f
# 1+XS512hDgncL0ijl3o7Kpxn3GIVWMGpkxGnzaqyat0QKYoeYmNp01icNXG/Opfr
# lFCPHCDqx5o7L5Zm42nnaf5bw9YrIBzBl5S0pVCB8s/LB6YwaMqDQtr8fwkklKSC
# Gtpqutg7yl3eGRiF+0XqDWFsnf5xXsQGmjzwxS55DxtmUuPI1j5f2kPThPXQx/ZI
# LV5FdZZ1/t0QoRuDwbjmUpW1R9d4KTlr4HhZl+NEK0rVlc7vCBfqgmRN/yPjyobu
# tKQhZHDr1eWg2mOzLukF7qr2JPUdvJscsrdf3/Dudn0xmWVHVZ1KJC+sK5e+n+T9
# e3M+Mu5SNPvUu+vUoCw0m+PebmQZBzcBkQ8ctVHNqkxmg4hoYru8QRt4GW3k2Q/g
# WEH72LEs4VGvtK0VBhTqYggT02kefGRNnQ/fztFejKqrUBXJs8q818Q7aESjpTtC
# /XN97t0K/3k0EH6mXApYTAA+hWl1x4Nk1nXNjxJ2VqUk+tfEayG66B80mC866msB
# sPf7Kobse1I4qZgJoXGybHGvPrhvltXhEBP+YUcKjP7wtsfVx95sJPC/QoLKoHE9
# nJKTBLRpcCcNT7e1NtHJXwikcKPsCvERLmTgyyIryvEoEyFJUX4GZtM7vvrrkTjY
# UQfKlLfiUKHzOtOKg8tAewIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAI
# BgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WM
# aiCPnshvMB0GA1UdDgQWBBSltu8T5+/N0GSh1VapZTGj3tXjSTBaBgNVHR8EUzBR
# ME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# RzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSB
# gzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsG
# AQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVz
# dGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEB
# CwUAA4ICAQCBGtbeoKm1mBe8cI1PijxonNgl/8ss5M3qXSKS7IwiAqm4z4Co2efj
# xe0mgopxLxjdTrbebNfhYJwr7e09SI64a7p8Xb3CYTdoSXej65CqEtcnhfOOHpLa
# wkA4n13IoC4leCWdKgV6hCmYtld5j9smViuw86e9NwzYmHZPVrlSwradOKmB521B
# XIxp0bkrxMZ7z5z6eOKTGnaiaXXTUOREEr4gDZ6pRND45Ul3CFohxbTPmJUaVLq5
# vMFpGbrPFvKDNzRusEEm3d5al08zjdSNd311RaGlWCZqA0Xe2VC1UIyvVr1MxeFG
# xSjTredDAHDezJieGYkD6tSRN+9NUvPJYCHEVkft2hFLjDLDiOZY4rbbPvlfsELW
# j+MXkdGqwFXjhr+sJyxB0JozSqg21Llyln6XeThIX8rC3D0y33XWNmdaifj2p8fl
# TzU8AL2+nCpseQHc2kTmOt44OwdeOVj0fHMxVaCAEcsUDH6uvP6k63llqmjWIso7
# 65qCNVcoFstp8jKastLYOrixRoZruhf9xHdsFWyuq69zOuhJRrfVf8y2OMDY7Bz1
# tqG4QyzfTkx9HmhwwHcK1ALgXGC7KP845VJa1qwXIiNO9OzTF/tQa/8Hdx9xl0RB
# ybhG02wyfFgvZ0dl5Rtztpn5aywGRu9BHvDwX+Db2a2QgESvgBBBijCCBq4wggSW
# oAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQELBQAwYjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIy
# MDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0
# IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTepl1Gh1tKD0Z5Mom2g
# sMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt+FeoAn39Q7SE2hHx
# c7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r07G1decfBmWNlCnT
# 2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dhgxndX7RUCyFobjch
# u0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfAcsW6Th+xtVhNef7X
# j3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpHIEPjQ2OAe3VuJyWQ
# mDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJSlRErWHRAKKtzQ87f
# SqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0z9JMq++bPf4OuGQq
# +nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y99xh3pP+OcD5sjCl
# TNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBIDfV8ju2TjY+Cm4T72
# wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXTdrnSDmuZDNIztM2x
# AgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBS6Ftlt
# TYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUH
# AQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYI
# KwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcw
# CAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAfVmOwJO2
# b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoNqilp/GnBzx0H6T5g
# yNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8Vc40BIiXOlWk/R3f7
# cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJodskr2dfNBwCnzvqLx1
# T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6skHibBt94q6/aesXmZ
# gaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82HhyS7T6NJuXdmkfFy
# nOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HNT7ZAmyEhQNC3EyTN
# 3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8zOYdBeHo46Zzh3SP9
# HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIXmVnKcPA3v5gA3yAW
# Tyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZE/6/pNHzV9m8BPqC
# 3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSFD/yYlvZVVCsfgPrA
# 8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQxggN2MIIDcgIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBS
# U0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAVEr/OUnQg5pr/bP1/lYRYw
# DQYJYIZIAWUDBAIBBQCggdEwGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwG
# CSqGSIb3DQEJBTEPFw0yNDAxMTgwOTU3MjhaMCsGCyqGSIb3DQEJEAIMMRwwGjAY
# MBYEFGbwKzLCwskPgl3OqorJxk8ZnM9AMC8GCSqGSIb3DQEJBDEiBCC9E7Es9fFH
# GQldeRvKH6PPVekGrneLVgnFGp/jta+RBDA3BgsqhkiG9w0BCRACLzEoMCYwJDAi
# BCDS9uRt7XQizNHUQFdoQTZvgoraVZquMxavTRqa1Ax4KDANBgkqhkiG9w0BAQEF
# AASCAgCdDp+00LTykI2iEnWn6bqyzM94uo1DAl41LV28UVXZVftpfrDjcPi0JMSv
# dOe13rgR3Fa7Q8zneR1E9bJy7B9+HRKyTwYgaBmV1GqWQCnt2xEw8fyXIOBGQEP/
# LTnmGMSBzsoN3WwR4pi6Kbcl2ca96u6eRslPhh6DWcaYlSfCFltsWxrCbwA0YrbI
# yeo0TtF1/29K567YAJTSHQhFruNWOUh9dLDepqIHQRjKvYLuMlN90uk4B2iaYHiO
# i/xZ89p1wwMuJGTVGLyEa+Onhv/V/pBFJGtX6jSzPS3ge4smGi56uEjRsfxpuVfu
# 70cPZ+9sxiNmaWgzXpkstQgcdrO2rBjVIFAxbuzUGIPLEq8zA8eyiw63r3nwYUCo
# dRS62djJJcPjcUf9qTRMLe1Xwc0bRzC0HvtjG+ZCFJSl5HQjy0+xv+EiFylcLNvT
# cWdMOJ73KP0t31eRxhgXx0Bzw+LhIESjWnYkJcUuS6kP/awi3yUNuMprm6obkyHY
# XouwaDxRXUQSY8a3NIuD6fFoD6xmatUE46zZXnKYvmA5xdp/lfJFtIbNAL4X/aom
# 7lRYRzKcOJkNYzofCc6HBO+OORB/xOVBZQsILJsuT9omCvqhvt+DmCEYqqj0OSMb
# fO2gIHlriIuPDVm2cFjmNn9xuVqD8PkNgezNESwJEVEd+kp9WA==
# SIG # End signature block
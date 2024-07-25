function Get-EnterprisePKIHealthStatus {
<#
.ExternalHelp PSPKI.Help.xml
#>
[OutputType('PKI.EnterprisePKI.X509HealthPath')]
[CmdletBinding(DefaultParameterSetName = '__CA')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = '__CA'
        )]
        [Alias('CA')]
        [PKI.CertificateServices.CertificateAuthority[]]$CertificateAuthority,
        [Parameter(Mandatory = $true, ParameterSetName = '__EndCerts')]
        [Security.Cryptography.X509Certificates.X509Certificate2[]]$Certificate,
        # configuration
        [int]$DownloadTimeout = 15,
        [ValidateRange(1,99)]
        [int]$CaCertExpirationThreshold = 80,
        [ValidateRange(1,99)]
        [int]$BaseCrlExpirationThreshold = 80,
        [ValidateRange(1,99)]
        [int]$DeltaCrlExpirationThreshold = 80,
        [ValidateRange(1,99)]
        [int]$OcspCertExpirationThreshold = 80
    )
    begin {
#region native function declarations
$cryptnetsignature = @"
[DllImport("cryptnet.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern bool CryptRetrieveObjectByUrl(
    //[MarshalAs(UnmanagedType.LPStr)]
    string pszUrl,
    //[MarshalAs(UnmanagedType.LPStr)]
    int pszObjectOid,
    int dwRetrievalFlags,
    int dwTimeout,
    ref IntPtr ppvObject,
    IntPtr hAsyncRetrieve,
    IntPtr pCredentials,
    IntPtr pvVerify,
    IntPtr pAuxInfo
);
"@
Add-Type -MemberDefinition $cryptnetsignature -Namespace "PKI.EnterprisePKI" -Name Cryptnet
$crypt32signature = @"
[DllImport("Crypt32.dll", SetLastError = true)]
public static extern Boolean CertFreeCertificateContext(
    [In] IntPtr pCertContext
);
[DllImport("Crypt32.dll", SetLastError = true)]
public static extern Boolean CertFreeCRLContext(
    [In] IntPtr pCrlContext
);
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
public struct CRL_CONTEXT {
    public int dwCertEncodingType;
    public IntPtr pbCrlEncoded;
    public int cbCrlEncoded;
    public IntPtr pCrlInfo;
    public IntPtr hCertStore;
}
"@
Add-Type -MemberDefinition $crypt32signature -Namespace "PKI.EnterprisePKI" -Name Crypt32
Add-Type @"
using System;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
namespace PKI.EnterprisePKI {
    public enum ChildStatus {
        Ok = 0x0,
        Warning = 0x100,
        Error = 0x8000,
    }
    // 0-49 -- common
    // 50-99 -- certs
    // 100-149 -- crls
    // 150-199 -- ocsp
    public enum UrlStatus {
        // common
        Ok = 0,
        // CRT/CRL/OCSP
        FailedToDownload = 10, NotYetValid = 11, Expired = 12, Expiring = 13,
        InvalidSignature = 14, NetworkRetrievalError = 15,
        // certs only
        Revoked = 50, InvalidCert = 51,
        // CRLs only. ScheduleExpired means that there is a "Next CRL Publish"
        // extension and current time is ahead of "Next CRL Publish value"
        InvalidIssuer = 100, ScheduleExpired = 101, InvalidBase = 102, InvalidCrlType = 103,
        NonCriticalDeltaIndicator = 104, StaleDelta = 105,
        // ocsp only
        MalformedRequest = 151, InternalError = 152, TryLater = 153,
        SignatureRequired = 155, Unauthorized = 156,
        ResponseInvalidData = 160, InvalidSignerCert = 161,
        // CAs only
        Offline,
    }
    public enum UrlType {
        Certificate, Crl, Ocsp
    }
    public class UrlElement {
        ushort error;

        Object hiddenObject;
        public String Name { get; set; }
        public UrlStatus Status {
            get {
                return (UrlStatus)(error & 0xff);
            }
        }
        public String ExtendedErrorInfo { get; set; }
        public Uri Url { get; set; }
        public DateTime? ExpirationDate { get; set; }
        public UrlType UrlType { get; set; }

        public Object GetObject() { return hiddenObject; }
        public void SetObject(Object obj) { hiddenObject = obj; }
        public void SetError(ushort statusCode) {
            error = statusCode;
        }
        public ushort GetError() {
            return error;
        }
        public override String ToString() {
            return Name + ": " + Url + ", expire: " + ExpirationDate + ", Status: " + Status;
        }
    }
    public class CAObject {
        bool isOffline;
        public String Name { get; set; }
        // can be 'Ok', 'Warning', or 'Error'
        public ChildStatus Status {
            get {
                if (isOffline) { return ChildStatus.Error; }
                if (URLs == null) {
                    return ChainStatus == X509ChainStatusFlags.NoError ? ChildStatus.Ok : ChildStatus.Error;
                }
                ChildStatus retValue = ChildStatus.Ok;
                foreach (var url in URLs) {
                    if ((url.GetError() & 0xFF00) > (int)retValue) { retValue = (ChildStatus)(url.GetError() & 0xFF00); }
                }
                return retValue;
            }
        }
        public X509ChainStatusFlags ChainStatus { get; set; }
        public String ExtendedErrorInfo { get; set; }
        public UrlElement[] URLs { get; set; }
        public void Offline() {
            isOffline = true;
        }
    }
    public class X509HealthPath {
        public String Name { get; set; }
        public ChildStatus Status {
            get {
                if (Childs == null || Childs.Length == 0) { return ChildStatus.Ok; }
                return Childs.Any(child => child.Status == ChildStatus.Error)
                    ? ChildStatus.Error
                    : (Childs.Any(child => child.Status == ChildStatus.Warning)
                        ? ChildStatus.Warning
                        : ChildStatus.Ok);
            }
        }
        public CAObject[] Childs { get; set; }
    }
}
"@
#endregion
        #region Error severity
        $s_ok = 0x0
        $s_warning = 0x100
        $s_error = 0x8000
        #endregion

        #region script internal config
        if ($PSBoundParameters.Verbose) {$VerbosePreference = "continue"}
        if ($PSBoundParameters.Debug) {$DebugPreference = "continue"}
        $timeout = $DownloadTimeout * 1000
        #endregion

        #region helper functions
        # returns [X509ChainElement[]]
        $chainRoots = @()
        function __getChain([Security.Cryptography.X509Certificates.X509Certificate2]$cert) {
            Write-Verbose "Entering certificate chaining engine."
            $chain = New-Object Security.Cryptography.X509Certificates.X509Chain
            $chain.ChainPolicy.RevocationMode = [Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
            $status = $chain.Build($cert)
            Write-Debug "Chain status for certificate '$($cert.Subject)': $status"
            if ($chainRoots -notcontains $chain.ChainElements[0].Certificate.Thumbprint) {
                $chainRoots += $chain.ChainElements[0].Certificate.Thumbprint
            }
            $retValue = New-Object Security.Cryptography.X509Certificates.X509ChainElement[] -ArgumentList $chain.ChainElements.Count
            $chain.ChainElements.CopyTo($retValue,0)
            $chain.Reset()
            $retValue
        }
        # returns [X509Certificate2] or [String] that contains error message
        function __downloadCert($url) {
            Write-Debug "Downloading cert URL: $url."
            $ppvObject = [IntPtr]::Zero
            if ([PKI.EnterprisePKI.Cryptnet]::CryptRetrieveObjectByUrl($url,1,4,$timeout,[ref]$ppvObject,
                [IntPtr]::Zero,
                [IntPtr]::Zero,
                [IntPtr]::Zero,
                [IntPtr]::Zero)
            ) {
                $cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $ppvObject
                Write-Debug "Certificate: $($cert.Subject)"
                $cert
                [void][PKI.EnterprisePKI.Crypt32]::CertFreeCertificateContext($ppvObject)
            } else {
                $hresult = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
                Write-Debug "URL error: $hresult"
                $CertRequest = New-Object -ComObject CertificateAuthority.Request
                $CertRequest.GetErrorMessageText($hresult,0)
                [SysadminsLV.PKI.Utils.CryptographyUtils]::ReleaseCom($CertRequest)
            }
        }
        # returns [X509CRL2] or [String] that contains error message
        function __downloadCrl($url) {
            Write-Debug "Downloading CRL URL: $url."
            $ppvObject = [IntPtr]::Zero
            if ([PKI.EnterprisePKI.Cryptnet]::CryptRetrieveObjectByUrl($url,2,4,$timeout,[ref]$ppvObject,
                [IntPtr]::Zero,
                [IntPtr]::Zero,
                [IntPtr]::Zero,
                [IntPtr]::Zero)
            ) {
                $crlContext = [Runtime.InteropServices.Marshal]::PtrToStructure($ppvObject,[Type][PKI.EnterprisePKI.Crypt32+CRL_CONTEXT])
                $rawData = New-Object byte[] -ArgumentList $crlContext.cbCrlEncoded
                [Runtime.InteropServices.Marshal]::Copy($crlContext.pbCrlEncoded,$rawData,0,$rawData.Length)
                $crl = New-Object SysadminsLV.PKI.Cryptography.X509Certificates.X509CRL2 (,$rawData)
                Write-Debug "CRL: $($crl.Issuer)"
                $crl
                [void][PKI.EnterprisePKI.Crypt32]::CertFreeCRLContext($ppvObject)
            } else {
                $hresult = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
                Write-Debug "URL error: $hresult"
                $CertRequest = New-Object -ComObject CertificateAuthority.Request
                $CertRequest.GetErrorMessageText($hresult,0)
                [SysadminsLV.PKI.Utils.CryptographyUtils]::ReleaseCom($CertRequest)
            }
        }
        # returns PSObject -- UrlPack
        function __getUrl ([Byte[]]$rawData, [bool]$isCert) {
            Write-Verbose "Getting URLs."
            Write-Debug "Getting URLs."
            $URLs = New-Object psobject -Property @{
                CDP = $null;
                AIA = $null;
                OCSP = $null;
                FreshestCRL = $null;
            }
            $ofs = "`n"
            if ($isCert) {
                $cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 @(,$rawData)
                # CRL Distribution Points
                Write-Debug "Fetching 'CRL Distribution Points' extension..."
                $e = $cert.Extensions["2.5.29.31"]
                if ($e) {
                    $asn = New-Object Security.Cryptography.AsnEncodedData (,$e.RawData)
                    $cdp = New-Object SysadminsLV.PKI.Cryptography.X509Certificates.X509CRLDistributionPointsExtension $asn, $false
                    $URLs.CDP = $cdp.GetURLs()
                    Write-Debug "Found $(($URLs.CDP).Length) CDP URLs."
                    if ($URLs.CDP) {$URLs.CDP | ForEach-Object {Write-Debug "$_"}}
                } else {
                    Write-Debug "Missing 'CRL Distribution Points' extension."
                }
                # Authority Information Access
                Write-Debug "Fetching 'Authority Information Access' extension..."
                $e = $cert.Extensions["1.3.6.1.5.5.7.1.1"]
                if ($e) {
                    $asn = New-Object Security.Cryptography.AsnEncodedData (,$e.RawData)
                    $aia = New-Object SysadminsLV.PKI.Cryptography.X509Certificates.X509AuthorityInformationAccessExtension $asn, $false
                    $URLs.AIA = $aia.CertificationAuthorityIssuer
                    Write-Debug "Found $(($URLs.AIA).Length) Certification Authority Issuer URLs."
                    if ($URLs.AIA) {$URLs.AIA | ForEach-Object {Write-Debug $_}}
                    $URLs.OCSP = $aia.OnlineCertificateStatusProtocol
                    Write-Debug "Found $(($URLs.OCSP).Length) On-line Certificate Status Protocol URLs."
                    if ($URLs.OCSP) {$URLs.OCSP | ForEach-Object {Write-Debug $_}}
                } else {
                    Write-Debug "Missing 'Authority Information Access' extension."
                }
                $URLs
            } else {
                Write-Debug "Fetching 'Freshest CRL' extension..."
                $crl = New-Object SysadminsLV.PKI.Cryptography.X509Certificates.X509CRL2 @(,$rawData)
                $e = $crl.Extensions["2.5.29.46"] # Freshest CRL
                if ($e) {
                    $URLs.FreshestCRL = $e.GetURLs()
                    Write-Debug "Found $(($URLs.FreshestCRL).Length) Freshest CRL URLs."
                    if ($URLs.FreshestCRL) {$URLs.FreshestCRL | ForEach-Object {Write-Debug $_}}
                } else {
                    Write-Debug "Missing 'Freshest CRL' extension."
                }
                $URLs
            }
        }
        # returns UrlElement
        function __verifyAIA {
            param (
                [PKI.EnterprisePKI.UrlElement]$urlElement,
                [Security.Cryptography.X509Certificates.X509ChainElement]$CAcert
            )
            Write-Verbose "Entering certificate validation routine."
            Write-Debug "Entering certificate validation routine."
            $cert = $urlElement.GetObject()
            Write-Debug "Leaf certificate: $($cert.Subject)."
            $parent = if ($cert.Subject -eq $cert.Issuer) {
                Write-Debug "Self-signed certificate, issuer is itself."
                $cert
            } else {
                Write-Debug "Issuer candidate: $($CAcert.Certificate.Subject)."
                $CAcert.Certificate
            }
            Write-Debug "Certificate start validity : $($cert.NotBefore)"
            Write-Debug "Certificate end validity   : $($cert.NotAfter)"
            $urlElement.ExpirationDate = $cert.NotAfter
            $subjComp = Compare-Object $cert.SubjectName.RawData $parent.SubjectName.RawData
            $pubKeyComp = Compare-Object $cert.PublicKey.EncodedKeyValue.RawData $parent.PublicKey.EncodedKeyValue.RawData
            $pubKeyParamComp = Compare-Object $cert.PublicKey.EncodedParameters.RawData $parent.PublicKey.EncodedParameters.RawData
            Write-Debug "Subject name binary comparison         : $(if ($subjComp) {'failed'} else {'passed'})"
            Write-Debug "Public key binary comparison           : $(if ($pubKeyComp) {'failed'} else {'passed'})"
            Write-Debug "Public key parameters binary comparison: $(if ($pubKeyParamComp) {'failed'} else {'passed'})"
            $fullTime = ($cert.NotAfter - $cert.NotBefore).TotalSeconds
            $elapsed = ((Get-Date) - $cert.NotBefore).TotalSeconds
            $errorCode = if ($subjComp -or $pubKeyComp -or $pubKeyParamComp) {
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::InvalidCert
            } elseif ($cert.NotBefore -gt (Get-Date)) {
                Write-Debug "Certificate is not yet valid."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::NotYetValid
            } elseif ($cert.NotAfter -lt (Get-Date)) {
                Write-Debug "Certificate is expired."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::Expired
            } elseif ($CaCertExpirationThreshold -lt $elapsed / $fullTime * 100) {
                Write-Debug "Certificate is about to expire. Elapsed $([int]($elapsed / $fullTime * 100))%"
                $s_warning -bor [PKI.EnterprisePKI.UrlStatus]::Expiring
            } else {
                Write-Debug "Certificate passed all validity checks."
                $s_ok -bor [PKI.EnterprisePKI.UrlStatus]::Ok
            }
            $urlElement.SetError($errorCode)
            $urlElement
        }
        # returns DateTime or Null (for CRL v1)
        function __getCrlNextPublish($crl) {
            $e = $crl.Extensions["1.3.6.1.4.1.311.21.4"]
            if (!$e) {return}
            $dt = try {
                    (New-Object SysadminsLV.Asn1Parser.Universal.Asn1UtcTime -ArgumentList @(,($e.RawData))).Value
                } catch {
                    [SysadminsLV.Asn1Parser.Asn1Utils]::DecodeGeneralizedTime($e.RawData)
                }
        }
        # returns UrlElement. $cert -- issuer candidate/X509ChainElement.
        function __verifyCDP {
            param(
                [PKI.EnterprisePKI.UrlElement]$urlElement,
                [Security.Cryptography.X509Certificates.X509ChainElement]$cert,
                [SysadminsLV.PKI.Cryptography.X509Certificates.X509CRL2]$BaseCRL,
                [switch]$DeltaCRL
            )
            Write-Verbose "Entering CRL validation routine..."
            Write-Debug "Entering CRL validation routine..."
            $crl = $urlElement.GetObject()
            Write-Debug "$($crl.Type) start validity : $($crl.ThisUpdate)"
            Write-Debug "$($crl.Type) end validity   : $($crl.NextUpdate)"
            $urlElement.ExpirationDate = $crl.NextUpdate
            [Numerics.BigInteger]$dcrlNumber = $crl.GetCRLNumber()
            Write-Debug "CRL number: $dcrlNumber"
            if ($DeltaCRL) {
                [Numerics.BigInteger]$bcrlNumber = $BaseCRL.GetCRLNumber()
                Write-Debug "Referenced Base CRL number: $bcrlNumber"
                $DeltaCrlIndicator = $crl.Extensions["2.5.29.27"]
                if ($DeltaCrlIndicator -ne $null) {
                    [UInt64]$indicator = [SysadminsLV.Asn1Parser.Asn1Utils]::DecodeInteger($DeltaCrlIndicator.RawData)
                    Write-Debug "Required minimum Base CRL number: $indicator"
                    [bool]$indicatorIsCritical = $DeltaCrlIndicator.Critical
                } else {
                    Write-Debug "Missing 'Delta CRL Indicator' CRL extension."
                }
            }
            $errorCode = if ($DeltaCRL -and ($crl.Type -ne "DeltaCrl")) {
                Write-Debug "Invalid CRL type. Expected Delta CRL, but received Base CRL."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::InvalidCrlType
            } elseif (!$DeltaCRL -and ($crl.Type -ne "BaseCrl")) {
                Write-Debug "Invalid CRL type. Expected Base CRL, but received Delta CRL."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::InvalidCrlType
            } elseif (!$crl.VerifySignature($cert.Certificate, $true)) {
                Write-Debug "CRL signature check failed."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::InvalidIssuer
            } elseif ($crl.ThisUpdate -gt [datetime]::Now) {
                Write-Debug "CRL is not yet valid."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::NotYetValid
            } elseif ($crl.NextUpdate -lt [datetime]::Now) {
                Write-Debug "CRL is expired."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::Expired
            } elseif ($DeltaCRL -and !$indicatorIsCritical) {
                Write-Debug "'Delta CRL Indicator' is not critical."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::NonCriticalDeltaIndicator
            } elseif ($DeltaCRL -and ($bcrlNumber -lt $indicator)) {
                Write-Debug "Base CRL number has lower version than version required by 'Delta CRL Indicator' extension."
                $s_error -bor [PKI.EnterprisePKI.UrlStatus]::InvalidBase
            } elseif ($DeltaCRL -and ($dcrlNumber -lt $bcrlNumber)) {
                Write-Debug "Delta CRL is outdated. A new version of Base CRL is available that overlaps current Delta CRL."
                $s_warning -bor [PKI.EnterprisePKI.UrlStatus]::StaleDelta
            } else {
                $dt = __getCrlNextPublish $crl
                if ($dt) {
                    if ((Get-Date) -gt $dt) {
                        Write-Debug "Scheduled CRL publish expired."
                        $urlElement.SetError($s_warning -bor [PKI.EnterprisePKI.UrlStatus]::ScheduleExpired)
                    }
                    $urlElement
                    return
                }
                $fullTime = ($crl.NextUpdate - $crl.ThisUpdate).TotalSeconds
                $elapsed = ((Get-Date) - $crl.ThisUpdate).TotalSeconds
                if ($DeltaCRL) {
                    if ($DeltaCrlExpirationThreshold -lt $elapsed / $fullTime * 100) {
                        Write-Debug "$($crl.Type) is about to expire. Elapsed: $([int]($elapsed / $fullTime * 100))%"
                        $s_warning -bor [PKI.EnterprisePKI.UrlStatus]::Expiring
                    } else {
                        
                        $s_ok -bor [PKI.EnterprisePKI.UrlStatus]::Ok
                    }
                } else {
                    if ($BaseCrlExpirationThreshold -lt $elapsed / $fullTime * 100) {
                        Write-Debug "$($crl.Type) is about to expire. Elapsed: $([int]($elapsed / $fullTime * 100))%"
                        $s_warning -bor [PKI.EnterprisePKI.UrlStatus]::Expiring
                    } else {
                        $s_ok -bor [PKI.EnterprisePKI.UrlStatus]::Ok
                    }
                }
            }
            $urlElement.SetError($errorCode)
            $urlElement
        }
        # returns UrlElement
        function __verifyOCSP {
            param(
                [Security.Cryptography.X509Certificates.X509ChainElement]$cert,
                [PKI.EnterprisePKI.UrlElement]$urlElement
            )
            Write-Verbose "Entering OCSP validation routine..."
            Write-Debug "Entering OCSP validation routine..."
            Write-Debug "URL: $($urlElement.Url.AbsoluteUri)"
            $req = New-Object PKI.OCSP.OCSPRequest $cert.Certificate
            $req.URL = $urlElement.Url
            try {
                $resp = $req.SendRequest()
                $urlElement.SetObject($resp)
                $errorCode = if ($resp.ResponseStatus -ne [PKI.OCSP.OCSPResponseStatus]::Successful) {
                    Write-Debug "OCSP server failed: $($resp.ResponseStatus)"
                    $s_error -bor (150 + $resp.ResponseStatus)
                } elseif (!$resp.SignatureIsValid) {
                    Write-Debug "OCSP response signature validation failed."
                    $s_error -bor [PKI.EnterprisePKI.UrlStatus]::InvalidSignature
                } elseif ([int]$resp.ResponseErrorInformation) {
                    Write-Debug "Response contains invalid data: $($resp.ResponseErrorInformation)"
                    $s_error -bor [PKI.EnterprisePKI.UrlStatus]::ResponseInvalidData
                } elseif (!$resp.SignerCertificateIsValid) {
                    Write-Debug "Signer certificate has one or more issues."
                    $s_error -bor [PKI.EnterprisePKI.UrlStatus]::InvalidSignerCert
                } else {
                    $totalValidity = ($resp.SignerCertificates[0].NotAfter - $resp.SignerCertificates[0].NotBefore).TotalSeconds
                    $elapsed = ((Get-Date) - $resp.SignerCertificates[0].NotBefore).TotalSeconds
                    if ($OcspCertExpirationThreshold -le $elapsed / $totalValidity * 100) {
                        Write-Debug "OCSP signing certificate is about to expire. Elapsed: $($elapsed / $totalValidity * 100)%"
                        $s_warning -bor [PKI.EnterprisePKI.UrlStatus]::Expiring
                    } else {
                        Write-Debug "OCSP response passed all checks."
                        $urlElement.ExpirationDate = $resp.Responses[0].NextUpdate
                        Write-Debug "OCSP response expires: $($urlElement.ExpirationDate)"
                        $s_ok -bor [PKI.EnterprisePKI.UrlStatus]::Ok
                    }
                }
                $urlElement.SetError($errorCode)
            } catch {
                $urlElement.SetError($s_error -bor [PKI.EnterprisePKI.UrlStatus]::NetworkRetrievalError)
                $urlElement.ExtendedErrorInfo = $_.Error.Exception.Message
            }
            $urlElement
        }
        # returns CAObject
        function __processCerts ($CAObject, $projectedChain) {
            Write-Verbose "Processing Certification Authority Issuer URLs..."
            Write-Debug "Processing Certification Authority Issuer URLs..."
            for ($n = 0; $n -lt $urlPack.AIA.Length; $n++) {
                $urlElement = New-Object PKI.EnterprisePKI.UrlElement -Property @{
                    Name = "AIA Location #$($n + 1)";
                    Url = $urlPack.AIA[$n];
                    UrlType = [PKI.EnterprisePKI.UrlType]::Certificate;
                }
                $obj = __downloadCert $urlElement.Url
                if ($obj -is [Security.Cryptography.X509Certificates.X509Certificate2]) {
                    $urlElement.SetObject($obj)
                    $urlElement = __verifyAIA $urlElement $projectedChain[$i + 1]
                } else {
                    Write-Debug "Failed to download certificate."
                    $urlElement.SetError($s_error -bor [PKI.EnterprisePKI.UrlStatus]::FailedToDownload)
                    $urlElement.ExtendedErrorInfo = $obj
                }
                $CAObject.URLs += $urlElement
            }
            $CAObject
        }
        # returns CAObject
        function __processOcsp ($CAObject, $projectedChain) {
            Write-Verbose "Processing On-line Certificate Status Protocol URLs..."
            Write-Debug "Processing On-line Certificate Status Protocol URLs..."
            for ($n = 0; $n -lt $urlPack.OCSP.Length; $n++) {
                $urlElement = New-Object PKI.EnterprisePKI.UrlElement -Property @{
                    Name = "OCSP Location #$($n + 1)";
                    Url = $urlPack.OCSP[$n];
                    UrlType = [PKI.EnterprisePKI.UrlType]::Ocsp;
                }
                $urlElement = __verifyOCSP $projectedChain[$i] $urlElement
                $CAObject.URLs += $urlElement
            }
            $CAObject
        }
        # returns X509HealthPath
        function __validateSinglePath {
            param(
                [Security.Cryptography.X509Certificates.X509Certificate2]$cert,
                # this parameter is not used
                [int]$keyIndex = -1
            )
            Write-Verbose "Entering certification path validation routine..."
            Write-Debug "Entering certification path validation routine..."
            if ([IntPtr]::Zero.Equals($cert.Handle)) {
                throw New-Object SysadminsLV.PKI.Exceptions.UninitializedObjectException "The certificate is not initialized."
                return
            }
            $projectedChain = __getChain $cert
            [void]($cert.Issuer -match "CN=([^,]+)")
            Write-Debug "CA name: $($matches[1])"
            $out = if ($keyIndex -lt 0) {
                New-Object PKI.EnterprisePKI.X509HealthPath -Property @{Name = $matches[1]}
            } else {
                New-Object PKI.EnterprisePKI.X509HealthPath -Property @{Name = "$($matches[1]) ($keyIndex)"}
            }
            for ($i = 0; $i -lt $projectedChain.Length; $i++) {
                Write-Debug "========================= $($projectedChain[$i].Certificate.Issuer) ========================="
                # skip self-signed certificate from checking
                if (!(
                    Compare-Object -ReferenceObject $projectedChain[$i].Certificate.SubjectName.RawData `
                        -DifferenceObject $projectedChain[$i].Certificate.IssuerName.RawData)) {
                    Write-Debug "Leaf certificate is self-signed, skip validation."
                    break
                }
                [void]($projectedChain[$i].Certificate.Issuer -match "CN=([^,]+)")
                $CAObject = if ($keyIndex -lt 0) {
                    New-Object PKI.EnterprisePKI.CAObject -Property @{Name = $matches[1]}
                } else {
                    New-Object PKI.EnterprisePKI.CAObject -Property @{Name = "$($matches[1]) ($keyIndex)"}
                }
                $projectedChain | ForEach-Object {[int]$CAObject.ChainStatus += [int]$_.Status}
                $urlpack = __getUrl $projectedChain[$i].Certificate.RawData $true
                # process and validate certificate issuer in the AIA extension
                $CAObject = __processCerts $CAObject $projectedChain
                # process and validate CDP extensions
                for ($n = 0; $n -lt $urlPack.CDP.Length; $n++) {
                    $deltas = @()
                    $urlElement = New-Object PKI.EnterprisePKI.UrlElement -Property @{
                        Name = "CDP Location #$($n + 1)";
                        Url = $urlPack.CDP[$n];
                        UrlType = [PKI.EnterprisePKI.UrlType]::Crl;
                    }
                    $obj = __downloadCrl $urlElement.Url
                    if ($obj -is [SysadminsLV.PKI.Cryptography.X509Certificates.X509CRL2]) {
                        $urlElement.SetObject($obj)
                        $urlElement = __verifyCDP $urlElement $projectedChain[$i + 1]
                        $urlPack2 = __getUrl ($urlElement.GetObject()).RawData $false
                        # process and validate FreshestCRL extension if exist
                        for ($m = 0; $m -lt $urlPack2.FreshestCRL.Length; $m++) {
                            # skip duplicate
                            if ($deltas | Where-Object {$_.Url -eq $urlPack2.FreshestCRL[$m]}) {
                                return
                            }
                            $urlElement2 = New-Object PKI.EnterprisePKI.UrlElement -Property @{
                                Name = "DeltaCRL Location #$($m + 1)";
                                Url = $urlPack2.FreshestCRL[$m];
                                UrlType = [PKI.EnterprisePKI.UrlType]::Crl;
                            }
                            $obj2 = __downloadCrl $urlElement2.Url
                            if ($obj2 -is [SysadminsLV.PKI.Cryptography.X509Certificates.X509CRL2]) {
                                $urlElement2.SetObject($obj2)
                                $urlElement2 = __verifyCDP $urlElement2 $projectedChain[$i + 1] $obj -DeltaCRL
                            } else {
                                Write-Debug "Failed to download CRL."
                                $urlElement2.SetError($s_error -bor [PKI.EnterprisePKI.UrlStatus]::FailedToDownload)
                                $urlElement2.ExtendedErrorInfo = $obj2
                            }
                            $deltas += $urlElement2
                        }
                    } else {
                        Write-Debug "Failed to download CRL."
                        $urlElement.SetError($s_error -bor [PKI.EnterprisePKI.UrlStatus]::FailedToDownload)
                        $urlElement.ExtendedErrorInfo = $obj
                    }
                    $CAObject.URLs += $urlElement
                    $CAObject.URLs += $deltas
                }
                # process OCSP links in the AIA extension
                $CAObject = __processOcsp $CAObject $projectedChain
                $out.Childs += $CAObject
            }
            $out
        }
        #endregion
        Write-Debug "Initializing parameterset: $($PsCmdlet.ParameterSetName)."
    }
    process {
        switch ($PsCmdlet.ParameterSetName) {
            '__CA' {
                foreach ($CA in $CertificateAuthority) {
                    if (!$CA.Ping()) {
                        Write-Debug "$($CA.DisplayName): ICertAdmin is down."
                        $retValue = New-Object PKI.EnterprisePKI.CAObject -Property @{Name = $CA.DisplayName}
                        $retValue.Offline()
                        $retValue
                        return
                    }
                    if (!$CA.Type.StartsWith("Enterprise")) {
                        Write-Debug "$($CA.DisplayName): not supported edition. Current: $($CA.Type)."
                        throw "Only Enterprise CAs are supported by this parameterset."
                    }
                    Write-Verbose ("{0} {1} {0}" -f ('=' * 20), $CA.DisplayName)
                    Write-Debug ("{0} {1} {0}" -f ('=' * 20), $CA.DisplayName)
                    Write-Debug "$($CA.DisplayName): retrieving CA Exchange certificate."
                    $xchg = $CA.GetCAExchangeCertificate()
                    __validateSinglePath $xchg
                }
            }
            '__EndCerts' {
                $Certificate | ForEach-Object {__validateSinglePath $_}
            }
        }
    }
}
# SIG # Begin signature block
# MIIxEgYJKoZIhvcNAQcCoIIxAzCCMP8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCClx+MFkNmeLvIF
# F9GRNSsRcvIWL7QT+EIH2qzR+xwE/KCCFgowggQyMIIDGqADAgECAgEBMA0GCSqG
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
# 9fxAfjGCGl4wghpaAgEBMGgwVDELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3Rp
# Z28gTGltaXRlZDErMCkGA1UEAxMiU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5n
# IENBIFIzNgIQEfd03RltdNDaAqLltlkfXzANBglghkgBZQMEAgEFAKCBhDAYBgor
# BgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBp
# KUmpVUMPCDwy87DhMmBPfZ4Q57lvXpDvunoe5PxUQjANBgkqhkiG9w0BAQEFAASC
# AgC46da1t3yyhO73B1W2eE2l+bXwiTpBoEEHAZVsyzHlHw48z8P2GDM0SPQzjRN6
# DwxF9f5i8gi+hHUvg50Z66nGDLOnVJuXKp4Zp5oW0cY6aJWbO9Y+pcjU8iJJg1wx
# OWSNazmP5Ty1uleJaUoIb8gXIqxULZwuBP7HpRRzGOXrqrL6uqcPU4uWfNnU3M1U
# Z+Fn1C4thpEjZPWf0AKDa2r015eWiBfEtZkMFB2c73S3mRq4E2tF+SuwxGx48gnx
# cvBfPxzPVmH/nWvpw48slPY273m0PCX0XoISfMH6BKeLqVb4rWjz3RL001WNHSe9
# Z7v4t1Cb5kDbGO20qTNIeTBWHcGPo9AywElNUbHxANIio6ft8iF4mNP9xsYI7wKJ
# yfCfMGr+581hnNW3BD7oW102uh41KU8apd4w8sI1zZX37YPknD8DWh1b9gxoM7nc
# gKnIf4vxt+6Rq2/nEQBYpqp842WlWsRKXiV/s0l/ORiOFFS1Pee4nXR0u+oRVtPU
# kO9AVMPtZGAKsbBsch8GclWprNbLyclMxxFNMNIQYdIWcwUh4DGCcZX2FZ29ZFpS
# vIH8zesDWNbJ7E+gT6pW9WbJYYfzPdH3cjYcvtLk6S/TrVQ1gHxLsLOiKoynyM0y
# snZlNERcmLdcZptiEj/cCjyMbLzZfRflNWCieod76pb7HqGCF0Awghc8BgorBgEE
# AYI3AwMBMYIXLDCCFygGCSqGSIb3DQEHAqCCFxkwghcVAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAweAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCA/RGmsX5YN0LoRNEeApaRzXNk7GfeR1pGtzaqq68wdJwIRAN3W
# zEe5Jx4ic6rJ7g+PCuUYDzIwMjQwMTE4MDk1OTA4WqCCEwkwggbCMIIEqqADAgEC
# AhAFRK/zlJ0IOaa/2z9f5WEWMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjMwNzE0
# MDAwMDAwWhcNMzQxMDEzMjM1OTU5WjBIMQswCQYDVQQGEwJVUzEXMBUGA1UEChMO
# RGlnaUNlcnQsIEluYy4xIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDIz
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAo1NFhx2DjlusPlSzI+DP
# n9fl0uddoQ4J3C9Io5d6OyqcZ9xiFVjBqZMRp82qsmrdECmKHmJjadNYnDVxvzqX
# 65RQjxwg6seaOy+WZuNp52n+W8PWKyAcwZeUtKVQgfLPywemMGjKg0La/H8JJJSk
# ghraarrYO8pd3hkYhftF6g1hbJ3+cV7EBpo88MUueQ8bZlLjyNY+X9pD04T10Mf2
# SC1eRXWWdf7dEKEbg8G45lKVtUfXeCk5a+B4WZfjRCtK1ZXO7wgX6oJkTf8j48qG
# 7rSkIWRw69XloNpjsy7pBe6q9iT1HbybHLK3X9/w7nZ9MZllR1WdSiQvrCuXvp/k
# /XtzPjLuUjT71Lvr1KAsNJvj3m5kGQc3AZEPHLVRzapMZoOIaGK7vEEbeBlt5NkP
# 4FhB+9ixLOFRr7StFQYU6mIIE9NpHnxkTZ0P387RXoyqq1AVybPKvNfEO2hEo6U7
# Qv1zfe7dCv95NBB+plwKWEwAPoVpdceDZNZ1zY8SdlalJPrXxGshuugfNJgvOupr
# AbD3+yqG7HtSOKmYCaFxsmxxrz64b5bV4RAT/mFHCoz+8LbH1cfebCTwv0KCyqBx
# PZySkwS0aXAnDU+3tTbRyV8IpHCj7ArxES5k4MsiK8rxKBMhSVF+BmbTO77665E4
# 2FEHypS34lCh8zrTioPLQHsCAwEAAaOCAYswggGHMA4GA1UdDwEB/wQEAwIHgDAM
# BgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMCAGA1UdIAQZMBcw
# CAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6FtltTYUvcyl2mi91
# jGogj57IbzAdBgNVHQ4EFgQUpbbvE+fvzdBkodVWqWUxo97V40kwWgYDVR0fBFMw
# UTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3Rl
# ZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCBkAYIKwYBBQUHAQEE
# gYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBYBggr
# BgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNydDANBgkqhkiG9w0B
# AQsFAAOCAgEAgRrW3qCptZgXvHCNT4o8aJzYJf/LLOTN6l0ikuyMIgKpuM+AqNnn
# 48XtJoKKcS8Y3U623mzX4WCcK+3tPUiOuGu6fF29wmE3aEl3o+uQqhLXJ4Xzjh6S
# 2sJAOJ9dyKAuJXglnSoFeoQpmLZXeY/bJlYrsPOnvTcM2Jh2T1a5UsK2nTipgedt
# QVyMadG5K8TGe8+c+njikxp2oml101DkRBK+IA2eqUTQ+OVJdwhaIcW0z5iVGlS6
# ubzBaRm6zxbygzc0brBBJt3eWpdPM43UjXd9dUWhpVgmagNF3tlQtVCMr1a9TMXh
# RsUo063nQwBw3syYnhmJA+rUkTfvTVLzyWAhxFZH7doRS4wyw4jmWOK22z75X7BC
# 1o/jF5HRqsBV44a/rCcsQdCaM0qoNtS5cpZ+l3k4SF/Kwtw9Mt911jZnWon49qfH
# 5U81PAC9vpwqbHkB3NpE5jreODsHXjlY9HxzMVWggBHLFAx+rrz+pOt5Zapo1iLK
# O+uagjVXKBbLafIymrLS2Dq4sUaGa7oX/cR3bBVsrquvczroSUa31X/MtjjA2Owc
# 9bahuEMs305MfR5ocMB3CtQC4Fxguyj/OOVSWtasFyIjTvTs0xf7UGv/B3cfcZdE
# Qcm4RtNsMnxYL2dHZeUbc7aZ+WssBkbvQR7w8F/g29mtkIBEr4AQQYowggauMIIE
# lqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0y
# MjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBH
# NCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9GeTKJt
# oLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0hNoR
# 8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZljZQp
# 09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAshaG43
# IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVYTXn+
# 149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1bicl
# kJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCirc0PO
# 30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+Drhk
# Kvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA+bIw
# pUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42PgpuE+
# 9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzSM7TN
# sQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuhbZ
# bU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUF
# BwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEG
# CCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAX
# MAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1ZjsCT
# tm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8dB+k+
# YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVpP0d3
# +3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp876i8
# dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2nrF5
# mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3ZpHx
# cpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQtxMk
# zdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc4d0j
# /R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+YAN8g
# Fk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZvAT6
# gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQrH4D6
# wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIFjTCCBHWgAwIBAgIQDpsYjvnQ
# Lefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYD
# VQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAw
# WhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QN
# xDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DC
# srp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTr
# BcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463JT17l
# Necxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WC
# QTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1
# EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KS
# Op493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAs
# QWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUO
# UlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtv
# sauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCC
# ATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQD
# AgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaG
# NGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9D
# XFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6
# Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuW
# cqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLih
# Vo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBj
# xZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02f
# c7cBqZ9Xql4o4rmUMYIDdjCCA3ICAQEwdzBjMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQg
# UlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAFRK/zlJ0IOaa/2z9f5WEW
# MA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAc
# BgkqhkiG9w0BCQUxDxcNMjQwMTE4MDk1OTA4WjArBgsqhkiG9w0BCRACDDEcMBow
# GDAWBBRm8CsywsLJD4JdzqqKycZPGZzPQDAvBgkqhkiG9w0BCQQxIgQgAypjk+wJ
# spaR+EuHnkmfYuOU/pSD1Wg6kfNWKjXY6tkwNwYLKoZIhvcNAQkQAi8xKDAmMCQw
# IgQg0vbkbe10IszR1EBXaEE2b4KK2lWarjMWr00amtQMeCgwDQYJKoZIhvcNAQEB
# BQAEggIACKDpEVkutvnhF4lm3LyhYB7xYgMWnkUeEq4uX7smvVMyjQoZtTpbtVKT
# tSy4gm45yNTj8hXnIS/bQcRGxWp2qKicCpnw8XH4smFpmI51naeNgq21lDx3gU57
# heOvS+cmgIibNgAdToKkmnUsm1oVvg85UbYU/XcTM3xf/AQU7xufQ6QRotI+ULj6
# x45obbGzU8RI1+tCRMJ0rL+VaxM9g4Ngxf3HUh4vGAR/5HXFN0EkfCnrad2FGeXs
# Rjr1y4Brq9g8ueey/QlKT//LFnO6B8BgEIYluQ+l9+quuq4Gf9X21+q2Td47dfQO
# C7cTQn7AngEJFKVhrag9B00Q1yZ3UaoMUddbUP8Z8R2FjTqki+PDE5esORM+nZwY
# SabHN+0+j3YueMrvJavsqftqXHF2lbsOS6UVl1bbwv+nNjHNWCDZ4yjb3nL5vYLO
# 2uQSomEBQtCmSVhUDMgxtGvZ/bXeqC0l3zD66EjH5tDeMs5ujCkQb0MHM0NmWjIg
# JuchiAT/RFWvxJopxgf/TRr2PDcPwjXvvVGNIb4kKcWcW2kNnvPdRmoBQDY5JJUn
# ADQa9Y/YB9sdaF38TNmZgpGLfktM/wD4+fYN9/jvhqTGzdY1ZWh3vGwn27osijnC
# YHMyK1qRPumcX90R4M9KP98I6hbhWm5v/ngXKQgsFLZq0RJD/wQ=
# SIG # End signature block

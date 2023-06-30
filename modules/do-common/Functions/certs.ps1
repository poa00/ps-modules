<#
.SYNOPSIS
Add CommonName, SubjectAlternativeName, SubjectKeyIdentifier and AuthorityKeyIdentifier properties to X509 certificate.

.PARAMETER Certificate
X509Certificate2 certificate.
#>
function Add-CertificateProperties {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    begin {
        # instantiate list for storing X509 certificates
        $certs = [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate2]]::new()
    }

    process {
        # Common Name
        $cn = [regex]::Match($Certificate.Subject, '(?<=CN=)(.)+?(?=,|$)')
        if ($cn) {
            $cn = $cn.Value.Trim().Trim('"')
            $Certificate | Add-Member -MemberType NoteProperty -Name 'CommonName' -Value $cn -PassThru `
            | Add-Member -MemberType AliasProperty -Name 'CN' -Value CommonName
        }
        # Subject Alternative Name
        $san = $Certificate.Extensions.Where({ $_.Oid.FriendlyName -match 'Subject Alternative Name' })
        if ($san) {
            $san = $san.Format(1).Trim()
            $Certificate `
            | Add-Member -MemberType NoteProperty -Name 'SubjectAlternativeName' -Value $san -PassThru `
            | Add-Member -MemberType AliasProperty -Name 'SAN' -Value SubjectAlternativeName
        }
        # Subject Key Identifier
        $ski = $Certificate.Extensions.Where({ $_.Oid.FriendlyName -match 'Subject Key Identifier' })
        if ($ski) {
            $ski = $ski.Format(1).Trim().Replace(':', '').ToUpper()
            $Certificate `
            | Add-Member -MemberType NoteProperty -Name 'SubjectKeyIdentifier' -Value $ski -PassThru `
            | Add-Member -MemberType AliasProperty -Name 'SKI' -Value SubjectKeyIdentifier
        }
        # Authority Key Identifier
        $aki = $Certificate.Extensions.Where({ $_.Oid.FriendlyName -match 'Authority Key Identifier' })
        if ($aki) {
            $aki = $aki.Format(1).Trim().Replace(':', '').Replace('KeyID=', '').ToUpper()
            $Certificate `
            | Add-Member -MemberType NoteProperty -Name 'AuthorityKeyIdentifier' -Value $aki -PassThru `
            | Add-Member -MemberType AliasProperty -Name 'AKI' -Value AuthorityKeyIdentifier
        }
        $certs.Add($Certificate)
    }

    end {
        return $certs
    }
}

<#
.SYNOPSIS
Create PEM encoded certificate from X509Certificate2 object.

.PARAMETER Certificate
X509Certificate2 certificate.
.PARAMETER AddHeader
Add certificate header with Issuer, Subject, Label, Serial and Fingerprint info.
#>
function ConvertTo-PEM {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[string]])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [switch]$AddHeader
    )

    begin {
        # instantiate list for storing PEM encoded certificates
        $pems = [System.Collections.Generic.List[string]]::new()
    }

    process {
        # convert certificate to base64
        $base64 = [System.Convert]::ToBase64String($Certificate.RawData)
        # add CommonName certificate property
        $Certificate = $Certificate | Add-CertificateProperties
        # build PEM encoded X.509 certificate
        $builder = [System.Text.StringBuilder]::new()
        if ($AddHeader) {
            $builder.AppendLine("# Issuer: $($Certificate.Issuer)") | Out-Null
            $builder.AppendLine("# Subject: $($Certificate.Subject)") | Out-Null
            $builder.AppendLine("# Label: $($Certificate.CommonName)") | Out-Null
            $builder.AppendLine("# Serial: $($Certificate.SerialNumber)") | Out-Null
            $builder.AppendLine("# SHA1 Fingerprint: $($Certificate.Thumbprint)") | Out-Null
        }
        $builder.AppendLine('-----BEGIN CERTIFICATE-----') | Out-Null
        for ($i = 0; $i -lt $base64.Length; $i += 64) {
            $length = [System.Math]::Min(64, $base64.Length - $i)
            $builder.AppendLine($base64.Substring($i, $length)) | Out-Null
        }
        $builder.AppendLine('-----END CERTIFICATE-----') | Out-Null
        # create object with parsed common name and PEM encoded certificate
        $pems.Add($builder.ToString())
    }

    end {
        return $pems
    }
}

<#
.SYNOPSIS
Create X509Certificate2 object(s) from PEM encoded certificate(s).

.PARAMETER InputObject
String with PEM encoded certificate.
.PARAMETER Path
Path to PEM encoded certificate file.
#>
function ConvertTo-X509Certificate {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromString')]
        [string]$InputObject,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'FromPath')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = "'{0}' is not a valid file path.")]
        [string]$Path,

        [ValidateNotNullorEmpty()]
        [string]$Output = 'PassThru'
    )

    begin {
        # evaluate Output parameter abbreviations
        $optSet = @('All', 'Compact', 'Extended', 'PassThru', 'Strip')
        $opt = $optSet -match "^$Output"
        if ($opt.Count -eq 0) {
            Write-Warning "Output parameter name '$Output' is invalid. Valid Option values are:`n`t $($optSet -join ', ')"
            break
        }

        # calculate properties for the specified Output
        $showCertProp = switch ($opt) {
            Compact {
                @{
                    TypeName   = @('System.DateTime', 'System.String')
                    MemberType = @('AliasProperty', 'Property')
                    Strip      = $true
                }
                continue
            }
            Extended {
                @{
                    TypeName   = @('System.Boolean', 'System.DateTime', 'System.Int32', 'System.IntPtr', 'System.String')
                    MemberType = @('AliasProperty', 'Property')
                    Strip      = $true
                }
                continue
            }
            Strip {
                @{ Strip = $true }
                continue
            }
            All { @{} }
        }

        # instantiate X509 certificate list
        $x509Certs = [System.Collections.Generic.List[Security.Cryptography.X509Certificates.X509Certificate2]]::new()
    }

    process {
        if ($PsCmdlet.ParameterSetName -eq 'FromPath') {
            # read certificate file
            $InputObject = (Resolve-Path $Path).ForEach({ [IO.File]::ReadAllText($_) })
        }
        # parse certificate string
        $pems = [regex]::Matches(
            $InputObject.Replace("`r`n", "`n"),
            '(?<=-{5}BEGIN CERTIFICATE-{5}\n)[\S\n]+(?=\n-{5}END CERTIFICATE-{5})'
        ).Value
        # convert PEM encoded certificates to X509 certificate objects
        foreach ($pem in $pems) {
            $x509Certs.Add([Security.Cryptography.X509Certificates.X509Certificate2]::new([Convert]::FromBase64String($pem)))
        }
    }

    end {
        switch ($opt) {
            PassThru {
                return $x509Certs
            }
            Default {
                return $x509Certs | Add-CertificateProperties | Show-Object @showCertProp
            }
        }
    }
}

<#
.SYNOPSIS
Get certificate(s) from specified Uri.

.PARAMETER Uri
Uri used for intercepting certificate.
.PARAMETER BuildChain
Switch whether to build full certificate chain.
.PARAMETER IgnoreValidation
Ignore validation errors for getting certificate/building chain.
#>
function Get-Certificate {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [switch]$BuildChain,

        [switch]$IgnoreValidation
    )

    begin {
        $ErrorActionPreference = 'Stop'

        $tcpClient = [System.Net.Sockets.TcpClient]::new($Uri, 443)
        if ($BuildChain) {
            $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
        }
        if ($IgnoreValidation) {
            $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream(), $false, { $true })
            if ($BuildChain) {
                $chain.ChainPolicy.VerificationFlags = [System.Security.Cryptography.X509Certificates.X509VerificationFlags]::AllFlags
            }
        } else {
            $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream())
        }
    }

    process {
        try {
            $sslStream.AuthenticateAsClient($Uri)
            $certificate = $sslStream.RemoteCertificate
        } finally {
            $sslStream.Close()
        }

        if ($BuildChain) {
            $isChainValid = $chain.Build($certificate)
            if ($isChainValid) {
                $certificate = $chain.ChainElements.Certificate
            } else {
                Write-Warning 'SSL certificate chain validation failed.'
            }
        }
    }

    end {
        return $certificate
    }
}

<#
.SYNOPSIS
Get certificate(s) from specified Uri using OpenSSL application.

.PARAMETER Uri
Uri used for intercepting certificate.
.PARAMETER BuildChain
Switch whether to build full certificate chain.
#>
function Get-CertificateOpenSSL {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [switch]$BuildChain
    )

    begin {
        $ErrorActionPreference = 'Stop'
        # check if openssl is installed
        if (-not (Get-Command openssl -CommandType Application)) {
            Write-Error 'Openssl not found. Script execution halted.'
        }
        # build openssl command
        $cmd = "Out-Null | openssl s_client$($BuildChain ? ' -showcerts' : '') -connect ${Uri}:443"
    }

    process {
        # run openssl command
        $chain = Invoke-Expression $cmd 2>$null
        if (-not $chain) {
            Write-Error "Name or service not known ($Uri)."
        }
        # parse pem encoded certificates from openssl output
        $pems = [regex]::Matches(
            [string]::Join("`n", $chain.Replace("`r`n", "`n")),
            '(?<=-{5}BEGIN CERTIFICATE-{5}\n)[\S\n]+(?=\n-{5}END CERTIFICATE-{5})'
        ).Value
        # convert PEM encoded certificates to X509 certificate objects
        foreach ($pem in $pems) {
            [Security.Cryptography.X509Certificates.X509Certificate2]::new([Convert]::FromBase64String($pem))
        }
    }
}

<#
.SYNOPSIS
Show certificate chain for a specified Uri.

.PARAMETER Uri
Uri used for intercepting certificate chain.
#>
function Show-Certificate {
    [CmdletBinding(DefaultParameterSetName = 'Compact')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [switch]$BuildChain,

        [Parameter(Mandatory, ParameterSetName = 'Extended')]
        [switch]$Extended,

        [Parameter(Mandatory, ParameterSetName = 'Strip')]
        [switch]$Strip,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    begin {
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'Stop'

        # build properties for Show-Object function
        $showCertProp = switch ($PsCmdlet.ParameterSetName) {
            Compact {
                @{
                    TypeName   = @('System.DateTime', 'System.String')
                    MemberType = @('AliasProperty', 'Property')
                    Strip      = $true
                }
                continue
            }
            Extended {
                @{
                    TypeName   = @('System.Boolean', 'System.DateTime', 'System.Int32', 'System.String')
                    MemberType = @('AliasProperty', 'Property')
                    Strip      = $true
                }
                continue
            }
            Strip {
                @{ Strip = $true }
                continue
            }
            All { @{} }
        }

        # clean PSBoundParameters for Get-Certificate function
        $PSBoundParameters.Remove('Extended') | Out-Null
        $PSBoundParameters.Remove('Strip') | Out-Null
        $PSBoundParameters.Remove('All') | Out-Null
    }

    process {
        $cert = try {
            Get-Certificate @PSBoundParameters | Add-CertificateProperties
        } catch {
            Write-Verbose 'Switching to OpenSSL for intercepting the certificate chain.'
            Get-CertificateOpenSSL @PSBoundParameters | Add-CertificateProperties
        }
    }

    end {
        $cert | Show-Object @showCertProp
    }
}

<#
.SYNOPSIS
Show certificate chain for a specified Uri.

.PARAMETER Uri
Uri used for intercepting certificate chain.
#>
function Show-CertificateChain {
    [CmdletBinding(DefaultParameterSetName = 'Compact')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [Parameter(Mandatory, ParameterSetName = 'Extended')]
        [switch]$Extended,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    begin {
        $PSBoundParameters.Add('BuildChain', $true)
    }

    process {
        Show-Certificate @PSBoundParameters
    }
}

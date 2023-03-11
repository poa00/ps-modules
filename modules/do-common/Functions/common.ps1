<#
.SYNOPSIS
Convert text from Base64 string.
.PARAMETER InputObject
Base64 encoded string to be converted.
#>
function ConvertFrom-Base64 {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputObject
    )

    process {
        $bytes = [System.Convert]::FromBase64String($InputObject)
        [System.Text.Encoding]::UTF8.GetString($bytes)
    }
}

<#
.SYNOPSIS
Convert text to Base64 string.
.PARAMETER InputObject
Text to be converted to Base64 string.
#>
function ConvertTo-Base64 {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputObject
    )

    process {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject)
        [System.Convert]::ToBase64String($bytes)
    }
}

<#
.SYNOPSIS
Convert all files in a directory to UTF8 and change EOLs from CRLF to LF.
.PARAMETER $Path
Directory to convert all files from.
#>
function ConvertTo-UTF8LF {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$Path = '.'
    )

    begin {
        $encoding = [System.Text.UTF8Encoding]::new($false)
        $fileCnt = 0
    }

    process {
        # get list of files to process, excluding .git subdirectory
        $files = (Get-ChildItem $Path -File -Force -Recurse).Where({ $_.DirectoryName -notmatch '(/|\\)\.git\b' })
        # convert files
        foreach ($file in $files) {
            $content = [System.IO.File]::ReadAllText($file).Replace("`r`n", "`n")
            [System.IO.File]::WriteAllText($file, $content, $encoding)
        }
        $fileCnt += $files.Count
    }

    end {
        Write-Host "Converted $fileCnt file(s)."
    }
}

<#
.SYNOPSIS
Get index(es) or a value(s) in provided array from selection menu.
.PARAMETER Array
Array of strings to get the selection menu.
.PARAMETER Message
Optional menu header to display.
.PARAMETER Value
Flag to return value(s) instead of index(es).
.PARAMETER List
Flag to choose from selection list instead of single value.
#>
function Get-ArrayIndexMenu {
    [CmdletBinding(DefaultParameterSetName = 'Index')]
    [OutputType([int], ParameterSetName = 'Index')]
    [OutputType([string], ParameterSetName = 'Value')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [object[]]$Array,

        [Parameter(Position = 1)]
        [string]$Message,

        [Parameter(Mandatory, ParameterSetName = 'Value')]
        [switch]$Value,

        [switch]$List
    )

    begin {
        # create selection menu
        $menu = if ($Array[0].PSObject.Properties.Name.Count -gt 1) {
            $Array `
            | Select-Object @{ N = '#'; E = { $Array.IndexOf($_) } }, @{ N = ' '; E = { '-' } }, * `
            | Format-Table -AutoSize `
            | Out-String
        } else {
            $Array.ForEach({ [PSCustomObject]@{ '#' = $Array.IndexOf($_); ' ' = '-'; 'V' = $_ } }) `
            | Format-Table -AutoSize -HideTableHeaders `
            | Out-String
        }
        # create prompt message
        if (-not $Message) {
            $Message = $List ? 'Enter comma/space separated selection list' : 'Enter selection'
        }
        $msg = "`n`e[4m$Message`e[0m:`n$menu"
    }

    process {
        # read and validate input
        do {
            [array]$inputArray = (Read-Host -Prompt $msg).Split([char[]]@(' ', ','), [StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Unique
        } while (($inputArray.ForEach({ $_ -in 0..($Array.Count - 1) }) -contains $false) -or (-not $List -and $inputArray.Count -gt 1) -or (-not $inputArray))
    }

    end {
        return $Value ? $inputArray.ForEach{ $Array[$_] } : $inputArray
    }
}

<#
.SYNOPSIS
Get the aliases for any cmdlet.
#>
function Get-CmdletAlias {
    [CmdletBinding()]
    param (
        [string]$CmdletName
    )

    Get-Alias | `
        Where-Object -FilterScript { $_.Definition -match $CmdletName } | `
        Sort-Object -Property Definition, Name | `
        Select-Object -Property Definition, Name
}

Set-Alias -Name alias -Value Get-CmdletAlias

<#
.SYNOPSIS
Parse semantic version and return Major, Minor, Patch numbers.
#>
function Get-SemanticVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ [regex]::IsMatch($_, '^v?\d+\.\d+\.\d+$') }, ErrorMessage = "`e[1;4m{0}`e[22;24m is not valid version")]
        [string]$Version
    )

    $major, $minor, $patch = [int[]]$Version.Replace('v', '').Split('.')

    return [PSCustomObject]@{
        Major = $major
        Minor = $minor
        Patch = $patch
    }
}

<#
.SYNOPSIS
Print timespan in human readable format.
#>
function Format-Duration {
    [CmdletBinding()]
    param (
        [timespan]$TimeSpan
    )

    switch ($TimeSpan) {
        { $_.TotalMilliseconds -gt 0 -and $_.TotalMilliseconds -lt 10 } { '{0:N2}ms' -f $_.TotalMilliseconds }
        { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { '{0:N1}ms' -f $_.TotalMilliseconds }
        { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { '{0:N0}ms' -f $_.TotalMilliseconds }
        { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { '{0:N3}s' -f $_.TotalSeconds }
        { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { '{0:N2}s' -f $_.TotalSeconds }
        { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff') }
        { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss') }
        { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))" }
        Default { '0ms' }
    }
}

<#
.SYNOPSIS
Retry executing command if fails on HttpRequestException.
.PARAMETER Script
Script block of commands to execute.
#>
function Invoke-CommandRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The command to be invoked.')]
        [scriptblock]$Command,

        [Parameter(HelpMessage = 'The number of retries the command should be invoked.')]
        [int]$MaxRetries = 10
    )

    $retryCount = 0
    do {
        try {
            Invoke-Command -ScriptBlock $Command @PSBoundParameters
            $exit = $true
        } catch [System.Net.Http.HttpRequestException] {
            if ($_.Exception.TargetSite.Name -eq 'MoveNext' -and $retryCount -lt $MaxRetries) {
                if ($_.ErrorDetails) {
                    Write-Verbose $_.ErrorDetails.Message
                } else {
                    Write-Verbose $_.Exception.Message
                }
                $retryCount++
                Write-Host 'Retrying...'
            } else {
                Write-Verbose $_.Exception.GetType().FullName
                Write-Error $_
            }
        } catch [System.AggregateException] {
            if ($_.Exception.InnerException.GetType().Name -eq 'HttpRequestException' -and $retryCount -lt $MaxRetries) {
                Write-Verbose $_.Exception.InnerException.Message
                $retryCount++
                Write-Host 'Retrying...'
            } else {
                Write-Verbose $_.Exception.InnerException.GetType().FullName
                Write-Error $_
            }
        } catch {
            Write-Verbose $_.Exception.GetType().FullName
            Write-Error $_
        }
    } until ($exit)
}

<#
.SYNOPSIS
Generate a random string.
#>
function New-Password {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Int]$Size = 8,

        [Char[]]$Complexity = 'ULNS',

        [Char[]]$Exclude
    )
    $AllTokens = @();
    $Chars = @();
    $TokenSets = @{
        UpperCase = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        LowerCase = [Char[]]'abcdefghijklmnopqrstuvwxyz'
        Numbers   = [Char[]]'0123456789'
        Symbols   = [Char[]]'!#%&*+-<>@^_|~'
    }
    $TokenSets.Keys | Where-Object { $Complexity -Contains $_[0] } | ForEach-Object {
        $TokenSet = $TokenSets.$_ | Where-Object { $Exclude -cNotContains $_ } | ForEach-Object { $_ }
        if ($_[0] -cle 'Z') {
            $Chars += $TokenSet | Get-Random
        }
        $AllTokens += $TokenSet
    }
    while ($Chars.Count -lt $Size) {
        $Chars += $AllTokens | Get-Random
    } -join ($Chars | Sort-Object { Get-Random })
}

<#
.SYNOPSIS
Check if PowerShell runs elevated.
#>
function Test-IsAdmin {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    process {
        $isAdmin = if ($IsWindows) {
            ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
        } else {
            ((id -u) -eq 0) ? $true : $false
        }
    }

    end {
        return $isAdmin
    }
}

<#
.SYNOPSIS
Get git log object.

.PARAMETER All
Switch whether to get commits from all branches.
.PARAMETER Start
Switch whether to get all commits, otherwise only last 50 will be shown.
.PARAMETER Quiet
Switch whether to write command.
#>
function Get-GitLogObject {
    param (
        [switch]$All,

        [switch]$Start,

        [switch]$Quiet
    )
    $cmd = "git log --pretty=format:`"%h`f%ai`f%D`f%s`f%an <%ae>`"$($All ? ' --all' : '')$($Start ? '' : ' -50')"
    if (-not $Quiet) {
        Write-Host $cmd.Replace("`f", '`t') -ForegroundColor Magenta
    }
    [string[]]$commit = Invoke-Expression $cmd
    if ($commit) {
        @("Commit`fDate`fReference`fSubject`fAuthor", $commit) `
        | ConvertFrom-Csv -Delimiter "`f" `
        | Select-Object Commit `
            , @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s') } } `
            , @{ Name = 'Reference'; Expression = { $_.Reference.Replace('origin/', '').Split(',')[0] } } `
            , Subject `
            , Author `
        | Sort-Object DateUTC
    }
}

<#
.SYNOPSIS
Write provided command with its arguments and then execute it.
You can suppress writing the command by providing -Quiet as one of the arguments.
You can suppress executing the command by providing -WhatIf as one of the arguments.

.PARAMETER Command
Command to be executed.
.PARAMETER Arguments
Command arguments to be passed to the provided command.
.PARAMETER Parameters
Control parameters: WhatIf, Quiet.
#>
function Invoke-WriteExecCmd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Command,

        [Parameter(ParameterSetName = 'Arguments')]
        [string[]]$Arguments,

        [Parameter(ParameterSetName = 'Parameters')]
        [string[]]$Parameters
    )

    begin {
        # clean up command from control parameters
        $Command = $Command -replace (' -WhatIf| -Quiet')
        # calculate control parameters
        $Parameters = $($Parameters ? $Parameters : $Arguments).Where({ $_ -match '^-WhatIf$|^-Quiet$' })
        # remove control parameters from arguments and quote arguments with spaces
        $Arguments = $Arguments.Where({ $_ -notmatch '^-WhatIf$|^-Quiet$' }).ForEach({ $_ -match '\s' ? "'$_'" : $_ })
        # build the command expression
        $cmd = "$Command $Arguments"
    }

    process {
        if ('-Quiet' -notin $Parameters) {
            # write the command
            Write-Host $cmd -ForegroundColor Magenta
        }
        if ('-WhatIf' -notin $Parameters) {
            # execute the command
            Invoke-Expression $cmd
        }
    }
}

<#
.SYNOPSIS
Get current branch name.
#>
function Get-GitCurrentBranch {
    git branch --show-current
}

<#
.SYNOPSIS
Resolve main, dev, stage branch names.

.PARAMETER BranchName
Name of the branch to switch to.
#>
function Get-GitResolvedBranch {
    [CmdletBinding()]
    param (
        [string[]]$BranchName
    )

    begin {
        [string]$BranchName = $BranchName.Where({ $_ -notmatch '^-WhatIf$|^-Quiet$' })
        $branchMatch = switch ($BranchName) {
            '' { '(^|/)dev(|el|elop|elopment)$|(^|/)ma(in|ster)$|(^|/)trunk$'; continue }
            d { '(^|/)dev(|el|elop|elopment)$'; continue }
            m { '(^|/)ma(in|ster)$'; continue }
            s { '(^|/)stage$'; continue }
            t { '(^|/)trunk$'; continue }
            Default { "(^|/)$BranchName$" }
        }
    }

    process {
        [string[]]$branches = (git branch -a --format='%(refname:short)').Where({ $_ -ne 'origin/HEAD' })
        if ($branches) {
            $branch = $branches.Replace('origin/', '') `
            | Sort-Object -Unique `
            | Select-String $branchMatch -Raw `
            | Select-Object -First 1
        }
        if (-not $branch) {
            if ($BranchName) {
                Write-Host "invalid reference: $BranchName`nvalid branch names: $branches"
            }
            break
        }
    }

    end {
        return $branch
    }
}

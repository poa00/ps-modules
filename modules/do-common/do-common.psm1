. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/net.ps1
. $PSScriptRoot/Functions/python.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Invoke-CommandRetry'
        'Get-ArrayIndexMenu'
        'Format-Duration'
        'Get-CmdletAlias'
        'New-Password'
        'Test-IsAdmin'
        'Set-DotnetLocation'
        # net
        'ConvertFrom-CIDR'
        # python
        'Invoke-CondaSetup'
        'Invoke-PySetup'
    )
    Variable = @()
    Alias  = @(
        'alias'
        'ics'
        'ips'
        'cds'
    )
}

Export-ModuleMember @exportModuleMemberParams

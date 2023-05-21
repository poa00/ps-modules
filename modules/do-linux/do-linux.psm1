. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-OsRelease'
        'Get-SysInfo'
        'Invoke-Sudo'
        'Invoke-SudoPS'
        'Invoke-FixExecutableBit'
    )
    Variable = @()
    Alias    = @(
        # common
        'osr'
        'gsi'
        '_'
        'sps'
        'feb'
    )
}

Export-ModuleMember @exportModuleMemberParams

$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/az.ps1
. $PSScriptRoot/Functions/azgraph.ps1

$exportModuleMemberParams = @{
    Function = @(
        # az
        'Connect-AzContext'
        'Get-MsoToken'
        'Set-SubscriptionMenu'
        'Invoke-AzApiRequest'
        # azgraph
        'Invoke-AzGraph'
        'Get-AzGraphSubscription'
        'Get-AzGraphResourceGroup'
        'Get-AzGraphResourceGroupByName'
        'Get-AzGraphResource'
        'Get-AzGraphResourceByName'
    )
    Variable = @()
    Alias    = @(
        'ssm'
    )
}

Export-ModuleMember @exportModuleMemberParams

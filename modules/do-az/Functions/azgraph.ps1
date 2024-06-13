<#
.SYNOPSIS
Azure Resource Graph functions.
.LINK
https://learn.microsoft.com/en-gb/azure/governance/resource-graph/reference/supported-tables-resources
#>


<#
.SYNOPSIS
Generic Search-AzGraph request.

.PARAMETER Query
Kusto query.
.PARAMETER SubscriptionId
Optional SubscriptionId to run query against.
.PARAMETER ManagementGroup
Optional ManagementGroup to run query against.
#>
function Invoke-AzGraph {
    [CmdletBinding(DefaultParametersetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Query,

        [Parameter(Mandatory, ParameterSetName = 'InSubscription')]
        [guid]$SubscriptionId,

        [Parameter(Mandatory, ParameterSetName = 'InMngmtGroup')]
        [guid]$ManagementGroup
    )

    begin {
        $param = @{
            First = 100
        }
        if ($PSBoundParameters.SubscriptionId) {
            $param.Subscription = $SubscriptionId
        } elseif ($PSBoundParameters.ManagementGroup) {
            $param.ManagementGroup = $ManagementGroup
        } else {
            $param.ManagementGroup = (Connect-AzContext).Tenant.Id
        }

        $result = [Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        $response = $null
        do {
            $response = Invoke-CommandRetry {
                Search-AzGraph @param -Query $Query -SkipToken $response.SkipToken
            }
            $response.ForEach({ $result.Add($_) })
        } while ($response.SkipToken)
    }

    end {
        return $result
    }
}


<#
.SYNOPSIS
Get Azure Subscriptions using AzGraph.

.PARAMETER SubscriptionId
Specifies the ID of the subscription to get.
.PARAMETER SubscriptionName
Specifies the name of the subscription to get.
.PARAMETER ManagementGroup
Specifies the ID of the ManagementGroup that contains subscriptions to get.
.PARAMETER Condition
Optional query condition.
#>
function Get-AzGraphSubscription {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([AzGraphSubscription[]])]
    param (
        [Alias('m')]
        [Parameter(Mandatory, ParameterSetName = 'InMngmtGroup')]
        [guid]$ManagementGroup,

        [Alias('i')]
        [Parameter(Mandatory, ParameterSetName = 'InSubscription')]
        [guid]$SubscriptionId,

        [Alias('n')]
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [string]$SubscriptionName,

        [Alias('c')]
        [Parameter(Mandatory, ParameterSetName = 'ByCondition')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [ValidateScript({ $_ -notmatch '\s*where\b' }, ErrorMessage = "`e[4mWHERE`e[24m keyword is not allowed.")]
        [string]$Condition
    )

    begin {
        # build filter
        $filter = if ($PSBoundParameters.SubscriptionName) {
            " and name =~ '$($PSBoundParameters.SubscriptionName)'"
        } elseif ($PSBoundParameters.Condition) {
            " and $($PSBoundParameters.Condition)"
        }

        # splat parameters
        $param = @{
            Query = [string]::Join("`n",
                'ResourceContainers',
                "| where type == 'microsoft.resources/subscriptions'$filter",
                '| project id, name, type, tenantId, subscriptionId, properties'
            )
        }

        if ($PSBoundParameters.ManagementGroup) {
            $param.ManagementGroup = $ManagementGroup
        } elseif ($PSBoundParameters.SubscriptionId) {
            $param.SubscriptionId = $SubscriptionId
        }
    }

    process {
        Write-Verbose "Query`n`n$($param.Query)`n"
        $response = Invoke-AzGraph @param
    }

    end {
        return [AzGraphSubscription[]]$response
    }
}


<#
.SYNOPSIS
Get resources group(s) in specified subscription.

.PARAMETER ResourceId
ID of the resource group to be retrieved.
.PARAMETER SubscriptionId
Specifies the ID of the subscription that contains resource groups to get.
.PARAMETER ManagementGroup
Specifies the ID of the ManagementGroup that contains resource groups to get.
.PARAMETER ResourceGroupName
Specifies the name of the resource group to get.
.PARAMETER Condition
Optional query condition.
#>
function Get-AzGraphResourceGroup {
    [CmdletBinding()]
    [OutputType([AzGraphResourceGroup[]])]
    param (
        [Alias('i')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Id')]
        [string]$ResourceId,

        [Alias('n')]
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'InSubscription')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [string]$ResourceGroupName,

        [Alias('c')]
        [Parameter(Mandatory, ParameterSetName = 'ByCondition')]
        [Parameter(ParameterSetName = 'InSubscription')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [ValidateScript({ $_ -notmatch '\s*where\b' }, ErrorMessage = "`e[4mWHERE`e[24m keyword is not allowed.")]
        [string]$Condition,

        [Alias('s')]
        [Parameter(Mandatory, ParameterSetName = 'InSubscription')]
        [guid]$SubscriptionId,

        [Alias('m')]
        [Parameter(Mandatory, ParameterSetName = 'InMngmtGroup')]
        [guid]$ManagementGroup
    )

    begin {
        # initialize parameter splat
        $param = @{}

        # build filter
        if ($PSBoundParameters.ResourceId) {
            $filter = $PSBoundParameters.ResourceId ? "id =~ '$ResourceId'" : ''
            $param.Subscription = ([AzGraphResourceGroup]$PSBoundParameters.ResourceId).SubscriptionId
        } else {
            $filter = "type == 'microsoft.resources/subscriptions/resourcegroups'"
            $filter += if ($PSBoundParameters.ResourceGroupName) {
                " and name =~ '$($PSBoundParameters.ResourceGroupName)'"
            } elseif ($PSBoundParameters.Condition) {
                " and $($PSBoundParameters.Condition)"
            }
        }

        # splat parameters
        $param.Query = [string]::Join("`n",
            'ResourceContainers',
            "| where $filter",
            '| join kind=leftouter (',
            '    ResourceContainers',
            '    | where type =~ "microsoft.resources/subscriptions"',
            '    | project subscription=name, subscriptionId',
            '    ) on subscriptionId',
            '| project id, name, type, tenantId, location, resourceGroup, subscriptionId, subscription, properties, tags'
        )

        if ($PSBoundParameters.ManagementGroup) {
            $param.ManagementGroup = $ManagementGroup
        } elseif ($PSBoundParameters.SubscriptionId) {
            $param.SubscriptionId = $SubscriptionId
        }
    }

    process {
        Write-Verbose "Query`n`n$($param.Query)`n"
        $response = Invoke-AzGraph @param
    }

    end {
        return [AzGraphResourceGroup[]]$response
    }
}


<#
.SYNOPSIS
Get Azure resource group by name.

.PARAMETER ResourceGroupName
Resource group name.
.PARAMETER SubscriptionId
Optional SubscriptionId to run query against.
.PARAMETER ManagementGroup
Optional ManagementGroup to run query against.
#>
function Get-AzGraphResourceGroupByName {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([AzGraphResourceGroup[]])]
    param (
        [Alias('n')]
        [Parameter(Mandatory, Position = 0)]
        [string]$ResourceGroupName,

        [Alias('s')]
        [Parameter(Mandatory, ParameterSetName = 'InSubscription')]
        [guid]$SubscriptionId,

        [Alias('m')]
        [Parameter(Mandatory, ParameterSetName = 'InMngmtGroup')]
        [guid]$ManagementGroup
    )

    begin {
        $param = @{
            ResourceGroupName = $PSBoundParameters.ResourceGroupName
        }

        if ($PSBoundParameters.SubscriptionId) {
            $param.SubscriptionId = $SubscriptionId
        } elseif ($PSBoundParameters.ManagementGroup) {
            $param.ManagementGroup = $ManagementGroup
        }
    }

    process {
        $rg = Get-AzGraphResourceGroup @param | Sort-Object subscription
        # select resource if query returned more than one result
        if ($rg.Count -gt 1) {
            Write-Warning 'Found more than one resource group matching the criteria!'
            $i = Get-ArrayIndexMenu -Array $rg.subscription -Message 'Select subscription of the resource group'
            $rg = $rg[$i]
        }
    }

    end {
        return $rg
    }
}


<#
.SYNOPSIS
Get resources using AzGraph.

.PARAMETER ResourceId
ID of the resource to be retrieved.
.PARAMETER SubscriptionId
Specifies the ID of the subscription that contains resources to get.
.PARAMETER ManagementGroup
Specifies the ID of the ManagementGroup that contains resources groups to get.
.PARAMETER ResourceGroupName
The resource group the resource that is retrieved belongs in.
.PARAMETER ResourceType
The resource type of the resource to be retrieved.
.PARAMETER ResourceName
The name of the resource to be retrieved.
.PARAMETER Condition
Optional query condition.
#>
function Get-AzGraphResource {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType([AzGraphResource[]])]
    param (
        [Alias('i')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Id')]
        [string]$ResourceId,

        [Alias('g')]
        [Parameter(Mandatory, ParameterSetName = 'Group')]
        [Parameter(Mandatory, ParameterSetName = 'GroupType')]
        [Parameter(ParameterSetName = 'InSubscription')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [string]$ResourceGroupName,

        [Alias('t')]
        [Parameter(Mandatory, ParameterSetName = 'Type')]
        [Parameter(Mandatory, ParameterSetName = 'GroupType')]
        [Parameter(ParameterSetName = 'InSubscription')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [ValidateScript({ $_ -match '\w+\.\w+/\w+' }, ErrorMessage = "`e[4m{0}`e[24m is not valid type.")]
        [string]$ResourceType,

        [Alias('n')]
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'Group')]
        [Parameter(ParameterSetName = 'Type')]
        [Parameter(ParameterSetName = 'Condition')]
        [Parameter(ParameterSetName = 'InSubscription')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [string]$ResourceName,

        [Alias('c')]
        [Parameter(Mandatory, ParameterSetName = 'Condition')]
        [Parameter(ParameterSetName = 'Group')]
        [Parameter(ParameterSetName = 'Type')]
        [Parameter(ParameterSetName = 'InSubscription')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [ValidateScript({ $_ -notmatch '\s*where\b' }, ErrorMessage = "`e[4mWHERE`e[24m keyword is not allowed.")]
        [string]$Condition,

        [Alias('s')]
        [Parameter(Mandatory, ParameterSetName = 'InSubscription')]
        [guid]$SubscriptionId,

        [Alias('m')]
        [Parameter(Mandatory, ParameterSetName = 'InMngmtGroup')]
        [guid]$ManagementGroup
    )

    begin {
        # initialize parameter splat
        $param = @{}

        # build filter
        if ($PSBoundParameters.ResourceId) {
            $filter = $PSBoundParameters.ResourceId ? "id =~ '$ResourceId'" : ''
            $param.Subscription = ([AzResource]$PSBoundParameters.ResourceId).SubscriptionId
        } else {
            $filter = $PSBoundParameters.ResourceGroupName ? "resourceGroup =~ '$($PSBoundParameters.ResourceGroupName)'" : ''
            $filter += $PSBoundParameters.ResourceType ? ($filter ? ' and ' : '') + "type =~ '$($PSBoundParameters.ResourceType)'" : ''
            $filter += $PSBoundParameters.ResourceName ? ($filter ? ' and ' : '') + "name =~ '$($PSBoundParameters.ResourceName)'" : ''
            $filter += $PSBoundParameters.Condition ? ($filter ? ' and ' : '') + $PSBoundParameters.Condition : ''
        }

        # splat parameters
        $param.Query = [string]::Join("`n",
            'Resources',
            "| where $filter",
            '| join kind=leftouter (',
            '    ResourceContainers',
            '    | where type =~ "microsoft.resources/subscriptions"',
            '    | project subscription=name, subscriptionId',
            '    ) on subscriptionId',
            '| project id, name, type, tenantId, kind, location, resourceGroup, subscriptionId, subscription, sku, properties, tags, identity'
        )

        if ($PSBoundParameters.SubscriptionId) {
            $param.SubscriptionId = $SubscriptionId
        } elseif ($PSBoundParameters.ManagementGroup) {
            $param.ManagementGroup = $ManagementGroup
        }
    }

    process {
        Write-Verbose "Query`n`n$($param.Query)`n"
        $response = Invoke-AzGraph @param
    }

    end {
        return [AzGraphResource[]]$response
    }
}


<#
.SYNOPSIS
Get Azure resource object by name and type.

.PARAMETER ResourceName
The name of the resource to be retrieved.
.PARAMETER ResourceType
The resource type of the resource to be retrieved.
.PARAMETER ExcludeTypes
Resource types to be excluded when retrieving the resource object.
.PARAMETER SubscriptionId
Optional SubscriptionId to run query against.
.PARAMETER ManagementGroup
Optional ManagementGroup to run query against.
#>
function Get-AzGraphResourceByName {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([AzGraphResource[]])]
    param (
        [Alias('n')]
        [Parameter(Mandatory, Position = 0)]
        [string]$ResourceName,

        [Alias('t')]
        [Parameter(Mandatory, ParameterSetName = 'ByType')]
        [Parameter(ParameterSetName = 'InSubscription')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [string]$ResourceType,

        [Alias('e')]
        [Parameter(Mandatory, ParameterSetName = 'ByCondition')]
        [Parameter(ParameterSetName = 'InSubscription')]
        [Parameter(ParameterSetName = 'InMngmtGroup')]
        [ValidateScript({ $false -notin $_.ForEach{ $_ -match '\w+\.\w+/\w+' } }, ErrorMessage = "`e[4m{0}`e[24m is not valid type.")]
        [string[]]$ExcludeTypes,

        [Alias('s')]
        [Parameter(Mandatory, ParameterSetName = 'InSubscription')]
        [guid]$SubscriptionId,

        [Alias('m')]
        [Parameter(Mandatory, ParameterSetName = 'InMngmtGroup')]
        [guid]$ManagementGroup
    )

    begin {
        $param = @{
            ResourceName = $PSBoundParameters.ResourceName
        }

        if ($PSBoundParameters.ResourceType) {
            $param.ResourceType = $PSBoundParameters.ResourceType
        } elseif ($PSBoundParameters.ExcludeTypes) {
            $typesList = $PSBoundParameters.ExcludeTypes.ForEach{ "`"$_`"" } -join ', '
            $param.Condition = "type !in~ ($typesList)"
        }

        if ($PSBoundParameters.SubscriptionId) {
            $param.SubscriptionId = $SubscriptionId
        } elseif ($PSBoundParameters.ManagementGroup) {
            $param.ManagementGroup = $ManagementGroup
        }
    }

    process {
        $resource = Get-AzGraphResource @param | Sort-Object subscription, resourceGroup, type
        # select resource if query returned more than one result
        if ($resource.Count -gt 1) {
            Write-Warning 'Found more than one resource matching the criteria!'
            $array = if ($ResourceType) {
                $resource | Select-Object resourceGroup, subscription
            } else {
                $resource | Select-Object type, resourceGroup, subscription
            }
            $i = Get-ArrayIndexMenu -Array $array -Message 'Select resource'
            $resource = $resource[$i]
        }
    }

    end {
        return $resource
    }
}

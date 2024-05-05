<#
.SYNOPSIS
Get list of git branches for the function ArgumentCompleter attribute.
#>
function ArgGitGetBranches {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # get list of all branches
    $branches = git branch --all --format='%(refname:short)'
    # build remote names filter
    $remoteFilter = [string]::Join('|', (git remote).ForEach({ "$_/?(HEAD)?" }))
    # filter list of branches
    [string[]]$possibleValues = $branches -replace $remoteFilter `
    | Where-Object { $_ } `
    | Sort-Object -Unique

    # return matching branches
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}

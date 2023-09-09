#
# Module manifest for module 'aliases-git'
#
# Generated by: szymono
#
# Generated on: 2023-04-04
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'aliases-git.psm1'

# Version number of this module.
ModuleVersion = '1.9.6'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'f3f1a553-f6f5-452d-affb-ab82ff97a896'

# Author of this module
Author = 'Szymon Osiecki'

# Company or vendor of this module
# CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) Szymon Osiecki. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This module contains git alias functions.'

# Minimum version of the PowerShell engine required by this module
CompatiblePSEditions = @('Core')
PowerShellVersion = '7.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    # helper
    'gglo'
    'ggloa'
    'ggloc'
    'ggloca'
    'ggrep'
    'ggrepa'
    'ggrepc'
    'ggrepca'
    # alias
    'ga'
    'gaa'
    'gapa'
    'gau'
    'gbl'
    'gb'
    'gba'
    'gbd'
    'gbd!'
    'gbdl'
    'gbdl!'
    'gbdm'
    'gbdm!'
    'gbnm'
    'gbr'
    'gbsu'
    'gbs'
    'gbsb'
    'gbsg'
    'gbsr'
    'gbss'
    'gcv'
    'gc!'
    'gca'
    'gcap'
    'gaca'
    'gacap'
    'gca!'
    'gaca!'
    'gcam'
    'gcamp'
    'gacm'
    'gacmp'
    'gcan!'
    'gcanp!'
    'gacn!'
    'gacnp!'
    'gcns!'
    'gcans!'
    'gacns!'
    'gcmsg'
    'gcmsgp'
    'gcempty'
    'gcn!'
    'gcnp!'
    'gcsm'
    'gcd'
    'gcf'
    'gcfg'
    'gcfge'
    'gcfgl'
    'gcfl'
    'gcfle'
    'gcfll'
    'gcl'
    'gclean'
    'gclean!'
    'gpristine'
    'gco'
    'gcount'
    'gcp'
    'gcpa'
    'gcpc'
    'gcps'
    'gd'
    'gdca'
    'gdt'
    'gdw'
    'gdct'
    'gf'
    'gfa'
    'gfa!'
    'gfo'
    'gg'
    'ggc'
    'ggca'
    'gge'
    'ggp'
    'ghh'
    'gignore'
    'gignored'
    'glo'
    'gloa'
    'glog'
    'gloga'
    'glol'
    'glola'
    'glon'
    'glona'
    'glong'
    'glonga'
    'glop'
    'glopa'
    'glos'
    'glosa'
    'glosp'
    'glospa'
    'gmb'
    'gmg'
    'gmgo'
    'gmt'
    'gmtvim'
    'gpl'
    'gpl!'
    'gpull'
    'gpullr'
    'gpullra'
    'gpullrav'
    'gpullrv'
    'gpush'
    'gpush!'
    'gpushd'
    'gpushdr'
    'gpushoat'
    'gpushsup'
    'gpushv'
    'grefresh'
    'grb'
    'grba'
    'grbc'
    'grbi'
    'grbo'
    'grbs'
    'gr'
    'grh'
    'grho'
    'grs'
    'grmb'
    'grmc'
    'grm!'
    'grmrc'
    'grmr!'
    'grr'
    'grrs'
    'grt'
    'grta'
    'grtrm'
    'grtrn'
    'grtsu'
    'grtup'
    'grtupp'
    'grtv'
    'gsw'
    'gsw!'
    'gswc'
    'gswd'
    'gswo'
    'gsmi'
    'gsmu'
    'gsps'
    'gstaa'
    'gstac'
    'gstad'
    'gstal'
    'gstap'
    'gstas'
    'gstast'
    'gst'
    'gstb'
    'gsts'
    'gsvnd'
    'gsvnr'
    'gt'
    'gts'
    'gtr'
    'gunignore'
    'gwch'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/szymonos/devops-scripts/modules/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/szymonos/devops-scripts/modules/aliases-git'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = 'beta'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

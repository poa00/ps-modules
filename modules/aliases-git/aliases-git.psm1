. $PSScriptRoot/Functions/alias.ps1
. $PSScriptRoot/Functions/helper.ps1
. $PSScriptRoot/Functions/internal.ps1

$exportModuleMemberParams = @{
    Function = @(
        # helper
        'Get-GitLogObject'
        'Remove-GitLocalBranches'
        # alias
        'ga'
        'gaa'
        'gapa'
        'gau'
        'gbl'
        'gb'
        'gba'
        'gbd'
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
        'gacam'
        'gacamp'
        'gcan!'
        'gcanp!'
        'gacan!'
        'gacanp!'
        'gcans!'
        'gacans!'
        'gcmsg'
        'gcmsgp'
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
        'gfo'
        'gg'
        'gge'
        'ggp'
        'ghh'
        'gignore'
        'gignored'
        'glg'
        'glga'
        'glgm'
        'glo'
        'gloa'
        'glog'
        'gloga'
        'glol'
        'glola'
        'glop'
        'glopa'
        'gls'
        'glsp'
        'gmg'
        'gmgom'
        'gmgum'
        'gmt'
        'gmtvim'
        'gpl'
        'gpull'
        'gpullr'
        'gpullra'
        'gpullrav'
        'gpullrv'
        'gpullum'
        'gpush'
        'gpush!'
        'gpushd'
        'gpushoat'
        'gpushsup'
        'gpushu'
        'gpushv'
        'grb'
        'grba'
        'grbc'
        'grbi'
        'grbm'
        'grbs'
        'gr'
        'grh'
        'grho'
        'grmb'
        'grs'
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
    Variable = @()
    Alias    = @(
        'gbda'
        'gglo'
    )
}

Export-ModuleMember @exportModuleMemberParams

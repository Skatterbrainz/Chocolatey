#requires -version 3

<#
.DESCRIPTION
  install, uninstall or upgrade chocolatey packages on remote machines

.PARAMETER Computer
  [string] (required) Name(s) of one or more machines

.PARAMETER ExecutionMode
  [string] (optional) 'install', 'uninstall' or 'upgrade'
  default = 'install'

.PARAMETER Package
  [string] (required) Name(s) of one or more packages

.EXAMPLE
  Manage-ChocoPackages.ps1 -Computer D001,D002 -ExecutionMode 'uninstall' -Package vlc,azcopy,putty
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Computer,
    [parameter(Mandatory=$False)]
        [ValidateSet('install','uninstall','upgrade')]
        [string] $ExecutionMode = 'install',
    [parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Package
)

$time1 = Get-Date -Format "hh:mm:ss"
Start-Transcript -Path "$($env:temp)\manage-chocopackages.log"

function Write-Line {
    param (
        [string] $Computer = $env:COMPUTERNAME, 
        [string] $Category, 
        [string] $Message
    )
    Write-Output "$Computer`t$((Get-Date).ToString("yyyy.MM.dd hh:mm:ss"))`t$Category`t$Computer`t$Message"
}

$result = 0

Write-Line -Computer "info" -Message "filtering $($Computer.count) computers by online status"
$Computer = $Computer | Where-Object { $(Test-Connection -ComputerName $_ -Quiet -Count 1) -eq $True }
Write-Line -Category "info" -Message "preparing to execute on $($Computer.count) computers"

$s = New-PSSession -ComputerName $Computer
if ($WhatIfPreference -eq $True) {
    Write-Line -Category "info" -Message "command = choco $ExecutionMode $Package --whatif"
    Invoke-Command -Session $s -ScriptBlock { choco $Using:ExecutionMode $Using:Package --whatif } -AsJob
    $j = Get-Job
    $j | Format-List -Property *
    $result = $j | Receive-Job
}
else {
    Write-Line -Category "info" -Message "command = choco $ExecutionMode $Package -y"
    Invoke-Command -Session $s -ScriptBlock { choco $Using:ExecutionMode $Using:Package -y } -AsJob
    $j = Get-Job
    $j | Format-List -Property *
    $result = $j | Receive-Job
}
Write-Output $result

$time2   = Get-Date -Format "hh:mm:ss"
$RunTime = New-TimeSpan $time1 $time2
$Difference = "{0:g}" -f $RunTime
Write-Line -Category "info" -Message "completed in (HH:MM:SS) $Difference"

Stop-Transcript

write-output $result

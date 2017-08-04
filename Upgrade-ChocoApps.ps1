<#
.DESCRIPTION
  Updates/upgrades all installed chocolatey packages on
  one or more remote computers
.PARAMETER Computer
  [string] (required) Name of computer(s) to administer
.NOTES

.EXAMPLE
  Upgrade-ChocoApps.ps1 -Computer D001,D002
#>

param (
    [parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Computer
)

$s = New-PSSession -ComputerName $Computer
Invoke-Command -Session $s -ScriptBlock { choco upgrade all -y } -AsJob
$j = Get-Job
$results = $j | Receive-Job
Write-Output $results

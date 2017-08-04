<#
.DESCRIPTION
  Returns installed chocolatey packages from 
  one or more remote computers in a single output
  which can be filtered/searched
.PARAMETER Computer
  [string] (required) Name of computer(s) to query
.NOTES
  Returns a hash table with [Computer] and [Package] keys
  so you can filter results by either if piped into
  Where-Object {$_.<keyname> <operator> <value>}
.EXAMPLE
  $results = Get-ChocoApps.ps1 -Computer D001,D002 
  $results | Where-Object {$_.Package -like 'notepad*'}
#>

param (
    [parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Computer
)

$s = New-PSSession -ComputerName $Computer
Invoke-Command -Session $s -ScriptBlock { choco list -lo | %{ @{Computer = $env:COMPUTERNAME; Package = $_.Trim() }} } -AsJob
$j = Get-Job
$results = $j | Receive-Job
Write-Output $results

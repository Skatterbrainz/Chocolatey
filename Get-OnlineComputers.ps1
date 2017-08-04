<#
.DESCRIPTION
  Returns an array of computers which respond to an ICMP request (ping)
  using an input array of names or IP addresses
.PARAMETER Computer
  [string] (required) Name of computer(s) to query
.EXAMPLE
  $online = Get-OnlineComputers.ps1 -Computer D001,D002,D003
#>

param (
    [parameter(Mandatory=$True, HelpMessage="Name of Computer(s) to query")]
        [ValidateNotNullOrEmpty()]
        [string[]] $Computer
)

$Computer | 
    Where-Object { $(Test-Connection -ComputerName $_ -Quiet -Count 1) -eq $True }

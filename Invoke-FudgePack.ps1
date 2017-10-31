#requires -RunAsAdministrator
#requires -version 3
<#
.SYNOPSIS
	Run Chocolatey package assignments using XML config file

.PARAMETER ControlFile
	[optional][string] Path or URI to appcontrol.xml file
	default: https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/appcontrol.xml
	
.PARAMETER LogFile
	[optional][string] Path to output log file
	default: $env:TEMP\fudgepack.log
	
.PARAMETER TestMode
	[optional][switch] WhatIf mode - no installs or removals executed
	
.NOTES
	1.0.2 - 10/28/2017 - skatterbrainz
	
.EXAMPLE
	
	Invoke-FudgePack -Verbose

.EXAMPLE

	Invoke-FudgePack -ControlFile "\\server\share\appcontrol.xml"

.EXAMPLE
	
	Invoke-FudgePack -TestMode -Verbose
	
#>

param (
	[parameter(Mandatory=$False)]
		[ValidateNotNullOrEmpty()]
		[string] $ControlFile = 'https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/appcontrol.xml',
	[parameter(Mandatory=$False)]
		[ValidateNotNullOrEmpty()]
		[string] $LogFile = "$($env:TEMP)\fudgepack.log",
	[parameter(Mandatory=$False)]
		[switch] $TestMode
)

<#
.SYNOPSIS
	Write or append log file with data
	
.PARAMETER Category
	[required] [string] One of 'Info', 'Warning' or 'Error'
	
.PARAMETER Message
	[required] [string] Text to append to log file
#>

function Write-FudgePackLog {
	param (
		[parameter(Mandatory=$True)]
			[ValidateSet('Info','Warning','Error')]
			[string] $Category,
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $Message
	)
	if ($Message -eq '---') {
		Write-Verbose '--------------------------------------------'
	}
	else {
		Write-Verbose "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message"
		"$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message" | Out-File $LogFile -Append -NoClobber -Encoding Default
	}
}

function Test-Admin { 
	$identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent() 
	$principal = New-Object System.Security.Principal.WindowsPrincipal($identity) 
	$admin = [System.Security.Principal.WindowsBuiltInRole]::Administrator 
	$principal.IsInRole($admin) 
} 

$error.Clear()

if (-not(Test-Admin)) {
	Write-Error "Must be run as an Administrator!!!"
	Write-Output -2
	break;
}
if (-not(Test-Path "$($env:ProgramData)\chocolatey\choco.exe" )) {
	iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

if ($controlfile.StartsWith("http")) {
	try {
		[xml]$controldata = Invoke-RestMethod -Uri $controlfile
	}
	catch {
		Write-FudgePackLog -Category "Error" -Message "failed to import data from Uri: $controlfile"
		Write-Output -3
		break;
	}
}
else {
	if (Test-Path $ControlFile) {
		try {
			[xml]$controldata = Get-Content -Path $ControlFile
		}
		catch {
			Write-FudgePackLog -Category "Error" -Message "unable to import control file: $ControlFile"
			Write-Output -4
			break;
		}
	}
	else {
		Write-FudgePackLog -Category "Error" -Message "unable to locate control file: $ControlFile"
		Write-Output -5
		break;
	}
}
if ($controldata) {
	$installs = $controldata.configuration.deployments.deployment | Where-Object {$_.enabled -eq "true" -and $_.device -eq $env:COMPUTERNAME}
	$removals = $controldata.configuration.removals.removal | Where-Object {$_.enabled -eq "true" -and $_.device -eq $env:COMPUTERNAME}
	Write-FudgePackLog -Category "Info" -Message "--------- installaation assignments ---------"
	if ($installs) {
		$devicename = $installs.device
		$runtime    = $installs.when
		$autoupdate = $installs.autoupdate
		$username   = $installs.user
		$extparams  = $installs.params
		Write-FudgePackLog -Category "Info" -Message "installations have been assigned to this computer"
		Write-FudgePackLog -Category "Info" -Message "assigned device: $devicename"
		Write-FudgePackLog -Category "Info" -Message "assigned runtime: $runtime"
		if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
			Write-FudgePackLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $installs.InnerText -split ','
			foreach ($pkg in $pkglist) {
				if ($extparams.length -gt 0) {
					Write-FudgePackLog -Category "Info" -Message "package: $pkg (params: $extparams)"
					if (-not $TestMode) {
						choco install $pkg $extparams
					}
					else {
						Write-Verbose "TEST MODE : $pkg"
					}
				}
				else {
					Write-FudgePackLog -Category "Info" -Message "package: $pkg"
					if (-not $TestMode) {
						choco install $pkg -y
					}
					else {
						Write-Verbose "TEST MODE: $pkg"
					}
				}
			} # foreach
		}
		else {
			Write-FudgePackLog -Category "Info" -Message "skip: not yet time to run this assignment"
		}
	}
	else {
		Write-FudgePackLog -Category "Info" -Message "NO installations have been assigned to this computer"
	}
	Write-FudgePackLog -Category "Info" -Message "--------- removal assignments ---------"
	if ($removals) {
		$devicename = $removals.device
		$runtime    = $removals.when
		$username   = $removals.user
		$extparams  = $removals.params
		Write-FudgePackLog -Category "Info" -Message "removals have been assigned to this computer"
		Write-FudgePackLog -Category "Info" -Message "assigned device: $devicename"
		Write-FudgePackLog -Category "Info" -Message "assigned runtime: $runtime"
		if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
			Write-FudgePackLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $removals.InnerText -split ','
			foreach ($pkg in $pkglist) {
				if ($extparams.length -gt 0) {
					Write-FudgePackLog -Category "Info" -Message "package: $pkg (params: $extparams)"
					if (-not $TestMode) {
						choco uninstall $pkg $extparams
					}
					else {
						Write-Verbose "TEST MODE : $pkg"
					}
				}
				else {
					Write-FudgePackLog -Category "Info" -Message "package: $pkg"
					if (-not $TestMode) {
						choco uninstall $pkg -y
					}
					else {
						Write-Verbose "TEST MODE : $pkg"
					}
				}
			} # foreach
		}
		else {
			Write-FudgePackLog -Category "Info" -Message "skip: not yet time to run this assignment"
		}
	}
	else {
		Write-FudgePackLog -Category "Info" -Message "NO removals have been assigned to this computer"
	}
}
Write-FudgePackLog -Category "Info" -Message "---- processing cycle finished ----"
if ($error.Count -eq 0) { Write-Output 0 } else { Write-Output -1 }

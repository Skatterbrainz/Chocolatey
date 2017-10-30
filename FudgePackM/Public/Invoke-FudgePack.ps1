#requires -RunAsAdministrator
#requires -version 3
<#
.SYNOPSIS
	Run Chocolatey package assignments and general device config ops using XML config file

.PARAMETER ControlFile
	[optional][string] Path or URI to appcontrol.xml file
	default: https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/control.xml
	
.PARAMETER LogFile
	[optional][string] Path to output log file
	default: $env:TEMP\fudgepack.log unless the [control] section of the XML file overrides it (it does)
	
.PARAMETER TestMode
	[optional][switch] WhatIf mode - no installs or removals executed

.PARAMETER Payload
	[optional] [string] One of 'All', 'Files', 'Folders', 'Registry', 'Installs', 'Removals' or 'Services'
	default is 'All'
	
.NOTES
	0.8.8 - 10/29/2017 - David Stein
	
.EXAMPLE
	Invoke-FudgePack -Verbose

.EXAMPLE
	Invoke-FudgePack -ControlFile "\\server\share\appcontrol.xml"

.EXAMPLE	
	Invoke-FudgePack -TestMode -Payload 'Registry' -Verbose

.EXAMPLE
	Invoke-FudgePack -Configure
#>
function Invoke-FudgePack {
	param (
		[parameter(Mandatory=$False, HelpMessage="Path or URI to XML control file")]
			[ValidateNotNullOrEmpty()]
			[string] $ControlFile = 'https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/control.xml',
		[parameter(Mandatory=$False, HelpMessage="Path to output log file")]
			[ValidateNotNullOrEmpty()]
			[string] $LogFile = "$($env:TEMP)\fudgepack.log",
		[parameter(Mandatory=$False, HelpMessage="Run in testing mode")]
			[switch] $TestMode,
		[parameter(Mandatory=$False, HelpMessage="Specify configuration task group to invoke from XML control file")]
			[ValidateSet('All','Installs','Removals','Folders','Files','Registry','Services')]
			[string] $Payload = 'All',
		[parameter(Mandatory=$False, HelpMessage="Configure options")]
			[switch] $Configure
	)
	Start-Trancscript
	Write-Verbose "script version: 0.8.8"
	$error.Clear()
	if ($Configure) {
		Set-FPConfiguration
	}
	else {
		Assert-Chocolatey
		$controlData = Get-FPControlData -FilePath $ControlFile
		if ($controldata) { 
			Invoke-FPTasks -DataSet $controlData 
		}
		else {
			Write-FudgePackLog -Category "Error" -Message "no data was returned from xml request"
		}
	}
	Write-FudgePackLog -Category "Info" -Message "---- processing cycle finished ----"
	#Stop-Transcript
	if ($error.Count -eq 0) { Write-Output 0 } else { Write-Output -1 }
}

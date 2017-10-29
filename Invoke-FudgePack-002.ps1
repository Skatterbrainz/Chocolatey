#requires -RunAsAdministrator
#requires -version 3
<#
.SYNOPSIS
	Run Chocolatey package assignments using XML config file

.PARAMETER ControlFile
	[optional][string] Path or URI to appcontrol.xml file
	default: https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/fudgepack/control.xml
	
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
		[string] $ControlFile = 'https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/fudgepack/control.xml',
	[parameter(Mandatory=$False)]
		[ValidateNotNullOrEmpty()]
		[string] $LogFile = "$($env:TEMP)\fudgepack.log",
	[parameter(Mandatory=$False)]
		[switch] $TestMode,
	[parameter(Mandatory=$False)]
		[ValidateSet('All','Installs','Removals','Folders','Files','Registry','Services')]
		[string] $Payload = 'All'
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

function Invoke-FPChocoInstalls {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePackLog -Category "Info" -Message "--------- installaation assignments ---------"
	if ($DataSet) {
		$devicename = $DataSet.device
		$runtime    = $DataSet.when
		$autoupdate = $DataSet.autoupdate
		$username   = $DataSet.user
		$extparams  = $DataSet.params
		Write-FudgePackLog -Category "Info" -Message "installations have been assigned to this computer"
		Write-FudgePackLog -Category "Info" -Message "assigned device: $devicename"
		Write-FudgePackLog -Category "Info" -Message "assigned runtime: $runtime"
		if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
			Write-FudgePackLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $DataSet.InnerText -split ','
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
}

function Invoke-FPChocoRemovals {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePackLog -Category "Info" -Message "--------- removal assignments ---------"
	if ($DataSet) {
		$devicename = $DataSet.device
		$runtime    = $DataSet.when
		$username   = $DataSet.user
		$extparams  = $DataSet.params
		Write-FudgePackLog -Category "Info" -Message "removals have been assigned to this computer"
		Write-FudgePackLog -Category "Info" -Message "assigned device: $devicename"
		Write-FudgePackLog -Category "Info" -Message "assigned runtime: $runtime"
		if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
			Write-FudgePackLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $DataSet.InnerText -split ','
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

function Invoke-FPRegistry {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePackLog -Category "Info" -Message "--------- registry assignments ---------"
	if ($DataSet) {
		Write-FudgePackLog -Category "Info" -Message "registry changes have been assigned to this computer"
		Write-FudgePackLog -Category "Info" -Message "assigned device: $devicename"
		foreach ($reg in $DataSet) {
			$regpath    = $reg.path
			$regval     = $reg.value
			$regdata    = $reg.data
			$regtype    = $reg.type
			Write-FudgePackLog -Category "Info" -Message "keypath: $regpath"
			Write-FudgePackLog -Category "Info" -Message "value: $regval"
			Write-FudgePackLog -Category "Info" -Message "data: $regdata"
			Write-FudgePackLog -Category "Info" -Message "type: $regtype"
			if (-not(Test-Path $regpath)) {
				Write-FudgePackLog -Category "Info" -Message "key not found, creating registry key"
				New-Item -Path $regpath -Force | Out-Null
				Write-FudgePackLog -Category "Info" -Message "updating value assignment to $regdata"
				New-ItemProperty -Path $regpath -Name $regval -Value $regdata -PropertyType $regtype -Force | Out-Null
			}
			else {
				Write-FudgePackLog -Category "Info" -Message "key already exists"
				$cv = Get-ItemProperty -Path $regpath -Name $regval | Select-Object -ExpandProperty $regval
				Write-FudgePackLog -Category "Info" -Message "current value of $regval is $cv"
				if ($cv -ne $regdata) {
					Write-FudgePackLog -Category "Info" -Message "updating value assignment to $regdata"
					New-ItemProperty -Path $regpath -Name $regval -Value $regdata -PropertyType $regtype -Force | Out-Null
				}
			}
		} # foreach
	}
	else {
		Write-FudgePackLog -Category "Info" -Message "NO registry changes have been assigned to this computer"
	}
}

function Invoke-FPServices {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePackLog -Category "Info" -Message "--------- services assignments ---------"
	foreach ($service in $DataSet) {
		$svcName   = $service.name
		$svcStart  = $service.startup
		$svcAction = $service.action
		Write-FudgePackLog -Category "Info" -Message "service name: $svcName"
		Write-FudgePackLog -Category "Info" -Message "startup should be: $svcStart"
		Write-FudgePackLog -Category "Info" -Message "requested action: $svcAction"
		try {
			$scfg = Get-Service -Name $svcName
			if ($scfg.StartType -ne $svcStart) {
				Write-FudgePackLog -Category "Info" -Message "current startup type is: $($scfg.StartType)"
				Write-FudgePackLog -Category "Info" -Message "setting service startup to: $svcStart"
				Set-Service -Name $svcName -StartupType $svcStart | Out-Null
			}
			if ($svcAction -eq 'start') {
				if ($scfg.Status -ne 'Running') {
					Write-FudgePackLog -Category "Info" -Message "starting service..."
					Start-Service -Name $svcName | Out-Null
				}
				else {
					Write-FudgePackLog -Category "Info" -Message "service is already running"
				}
			}
		}
		catch {
			Write-FudgePackLog -Category "Error" -Message "service not found: $svcName"
		}
	} # foreach
}

function Invoke-FPFolders {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePackLog -Category "Info" -Message "--------- folder assignments ---------"
	foreach ($folder in $DataSet) {
		$folderPath  = $folder.path
		$action = $folder.action
		Write-FudgePackLog -Category "Info" -Message "folder action assigned: $action"
		switch ($action) {
			'create' {
				Write-FudgePackLog -Category "Info" -Message "folder path: $folderPath"
				if (-not(Test-Path $folderPath)) {
					Write-FudgePackLog -Category "Info" -Message "creating new folder"
					mkdir -Path $folderPath -Force | Out-Null
				}
				else {
					Write-FudgePackLog -Category "Info" -Message "folder already exists"
				}
				break
			}
			'empty' {
				$filter = $folder.filter
				if ($filter -eq "") { $filter = "*.*" }
				if ($folder.recurse -eq "true") {
					Write-FudgePackLog -Category "Info" -Message "deleting $filter from $folderPath and subfolders"
					Get-ChildItem -Path $folderPath -Filter $filter -Recurse |
						foreach { Remove-Item -Path $_.FullName -ErrorAction SilentlyContinue }
					Write-FudgePackLog -Category "Info" -Message "some files may remain if they were in use"
				}
				else {
					Write-FudgePackLog -Category "Info" -Message "deleting $filter from $folderPath only"
					Get-ChildItem -Path $folderPath -Filter $filter -Recurse |
						foreach { Remove-Item -Path $_.FullName -ErrorAction SilentlyContinue }
					Write-FudgePackLog -Category "Info" -Message "some files may remain if they were in use"
				}
				break
			}
		} # switch
	} # foreach
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
	$regkeys  = $controldata.configuration.registry.reg | Where-Object {$_.enabled -eq "true" -and $_.device -eq $env:COMPUTERNAME}
	$services = $controldata.configuration.services.service | Where-Object {$_.enabled -eq "true" -and $_.device -eq $env:COMPUTERNAME}
	$folders  = $controldata.configuration.folders.folder | Where-Object {$_.enabled -eq "true" -and $_.device -eq $env:COMPUTERNAME}
	$files    = $controldata.configuration.files.file | Where-Object {$_.enabled -eq "true" -and $_.device -eq $env:COMPUTERNAME}
	if ($Payload -eq 'All' -or $Payload -eq 'Folders')  { Invoke-FPFolders -DataSet $folders }
	if ($Payload -eq 'All' -or $Payload -eq 'Installs') { Invoke-FPChocoInstalls -DataSet $installs }
	if ($Payload -eq 'All' -or $Payload -eq 'Removals') { Invoke-FPChocoRemovals -DataSet $removals }
	if ($Payload -eq 'All' -or $Payload -eq 'Registry') { Invoke-FPRegistry -DataSet $regkeys }
	if ($Payload -eq 'All' -or $Payload -eq 'Services') { Invoke-FPServices -DataSet $services }
}
Write-FudgePackLog -Category "Info" -Message "---- processing cycle finished ----"
if ($error.Count -eq 0) { Write-Output 0 } else { Write-Output -1 }

<#
.SYNOPSIS
	Private functions for running FudgePack	
#>

$FPRegPath  = "HKLM:\SOFTWARE\FudgePack"
$FPFilePath = "$($env:PROGRAMDATA)\FudgePack"

function Write-FudgePackLog {
	param (
		[parameter(Mandatory=$True)]
			[ValidateSet('Info','Warning','Error')]
			[string] $Category,
		[parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $Message
	)
	Write-Verbose "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message"
	"$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message" | 
		Out-File $LogFile -Append -NoClobber -Encoding Default
}

function Assert-Chocolatey {
	param ()
	Write-FudgePackLog -Category "Info" -Message "verifying chocolatey installation"
	if (-not(Test-Path "$($env:ProgramData)\chocolatey\choco.exe" )) {
		try {
			Write-FudgePackLog -Category "Info" -Message "installing chocolatey"
			iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
		}
		catch {
			Write-FudgePackLog -Category "Error" -Message $_.Exception.Message
			break
		}
	}
	else {
		Write-FudgePackLog -Category "Info" -Message "checking for newer version of chocolatey"
		choco upgrade chocolatey -y
	}
}

function Get-FPControlData {
	param (
		[parameter(Mandatory=$True, HelpMessage="Path or URI to XML control file")]
		[ValidateNotNullOrEmpty()]
		[string] $FilePath
	)
	Write-FudgePackLog -Category "Info" -Message "preparing to import control file: $FilePath"
	if ($FilePath.StartsWith("http")) {
		try {
			[xml]$result = Invoke-RestMethod -Uri $FilePath -UseBasicParsing
			$logpath = $result.configuration.controls.control | 
				Where-Object {$_.enabled -eq 'true' -and $_.type -eq 'logpath'} |
					Select-Object -ExpandProperty 'value'
			if ($logpath -eq "") { $LogFile = $logpath }
		}
		catch {
			Write-FudgePackLog -Category "Error" -Message "failed to import data from Uri: $FilePath"
			Write-Output -3
			break;
		}
	}
	else {
		if (Test-Path $FilePath) {
			try {
				[xml]$result = Get-Content -Path $FilePath
			}
			catch {
				Write-FudgePackLog -Category "Error" -Message "unable to import control file: $FilePath"
				Write-Output -4
				break;
			}
		}
		else {
			Write-FudgePackLog -Category "Error" -Message "unable to locate control file: $FilePath"
			Write-Output -5
			break;
		}
	}
	Write-Output $result
}

function Invoke-FPChocoInstalls {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePackLog -Category "Info" -Message "--------- installaation assignments ---------"
	if ($DataSet) {
		$deviceName = $DataSet.device
		$runtime    = $DataSet.when
		$autoupdate = $DataSet.autoupdate
		$username   = $DataSet.user
		$extparams  = $DataSet.params
		Write-FudgePackLog -Category "Info" -Message "assigned to device: $deviceName"
		Write-FudgePackLog -Category "Info" -Message "assigned runtime: $runtime"
		if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
			Write-FudgePackLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $DataSet.InnerText -split ','
			foreach ($pkg in $pkglist) {
				if ($extparams.length -gt 0) {
					Write-FudgePackLog -Category "Info" -Message "package: $pkg (params: $extparams)"
					if (-not $TestMode) {
						choco upgrade $pkg $extparams
					}
					else {
						Write-FudgePackLog -Category "Info" -Message "TEST MODE : choco upgrade $pkg $extparams"
					}
				}
				else {
					Write-FudgePackLog -Category "Info" -Message "package: $pkg"
					if (-not $TestMode) {
						choco upgrade $pkg -y
					}
					else {
						Write-FudgePackLog -Category "Info" -Message "TEST MODE: choco upgrade $pkg -y"
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
		$deviceName = $DataSet.device
		$runtime    = $DataSet.when
		$username   = $DataSet.user
		$extparams  = $DataSet.params
		Write-FudgePackLog -Category "Info" -Message "assigned to device: $deviceName"
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
						Write-FudgePackLog -Category "Info" -Message "TEST MODE : choco uninstall $pkg $extparams"
					}
				}
				else {
					Write-FudgePackLog -Category "Info" -Message "package: $pkg"
					if (-not $TestMode) {
						choco uninstall $pkg -y -r
					}
					else {
						Write-FudgePackLog -Category "Info" -Message "TEST MODE : choco uninstall $pkg -y -r"
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
			$deviceName = $reg.device
			Write-FudgePackLog -Category "Info" -Message "assigned to device: $deviceName"
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
		$svcName    = $service.name
		$svcStart   = $service.startup
		$svcAction  = $service.action
		$deviceName = $service.device
		Write-FudgePackLog -Category "Info" -Message "assigned to device: $deviceName"
		Write-FudgePackLog -Category "Info" -Message "service name: $svcName"
		Write-FudgePackLog -Category "Info" -Message "startup should be: $svcStart"
		Write-FudgePackLog -Category "Info" -Message "requested action: $svcAction"
		try {
			$scfg = Get-Service -Name $svcName
			$sst  = $scfg.StartType
			if ($svcStart -ne "" -and $scfg.StartType -ne $svcStart) {
				Write-FudgePackLog -Category "Info" -Message "current startup type is: $sst"
				Write-FudgePackLog -Category "Info" -Message "setting service startup to: $svcStart"
				Set-Service -Name $svcName -StartupType $svcStart | Out-Null
			}
			switch ($svcAction) {
				'start' {
					if ($scfg.Status -ne 'Running') {
						Write-FudgePackLog -Category "Info" -Message "starting service..."
						Start-Service -Name $svcName | Out-Null
					}
					else {
						Write-FudgePackLog -Category "Info" -Message "service is already running"
					}
					break
				}
				'restart' {
					Write-FudgePackLog -Category "Info" -Message "restarting service..."
					Restart-Service -Name $svcName -ErrorAction SilentlyContinue
					break
				}
				'stop' {
					Write-FudgePackLog -Category "Info" -Message "stopping service..."
					Stop-Service -Name $svcName -Force -NoWait -ErrorAction SilentlyContinue
					break
				}
			} # switch
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
		$deviceName  = $folder.device
		$action = $folder.action
		Write-FudgePackLog -Category "Info" -Message "assigned to device: $deviceName"
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
				Write-FudgePackLog -Category "Info" -Message "deleting $filter from $folderPath and subfolders"
				Get-ChildItem -Path "$folderPath" -Filter "$filter" -Recurse |
					foreach { Remove-Item -Path $_.FullName -Confirm:$False -Recurse -ErrorAction SilentlyContinue }
				Write-FudgePackLog -Category "Info" -Message "some files may remain if they were in use"
				break
			}
		} # switch
	} # foreach
}

function Invoke-FPFiles {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	Write-FudgePackLog -Category "Info" -Message "--------- file assignments ---------"
	foreach ($file in $DataSet) {
		$fileSource = $file.source
		$fileTarget = $file.target
		$action     = $file.action
		Write-FudgePackLog -Category "Info" -Message "file action assigned: $action"
		Write-FudgePackLog -Category "Info" -Message "source: $fileSource"
		Write-FudgePackLog -Category "Info" -Message "target: $fileTarget"
		switch ($action) {
			'download' {
				Write-FudgePackLog -Category "Info" -Message "downloading file"
				break
			}
			'rename' {
				Write-FudgePackLog -Category "Info" -Message "renaming file"
				break
			}
			'move' {
				Write-FudgePackLog -Category "Info" -Message "moving file"
				break
			}
		} # switch
	} # foreach
}

function Invoke-FPTasks {
	param (
		[parameter(Mandatory=$True)]
		$DataSet
	)
	$mypc = $env:COMPUTERNAME
	if ($PayLoad -eq 'Configure') {
		if (Set-FPConfiguration) {
			Write-Host "configuration has been updated"
		}
	}
	else {
		$installs = $DataSet.configuration.deployments.deployment | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$removals = $DataSet.configuration.removals.removal | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$regkeys  = $DataSet.configuration.registry.reg | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$services = $DataSet.configuration.services.service | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$folders  = $DataSet.configuration.folders.folder | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		$files    = $DataSet.configuration.files.file | 
			Where-Object {$_.enabled -eq "true" -and ($_.device -eq $mypc -or $_.device -eq 'all')}
		if ($folders)  { if ($Payload -eq 'All' -or $Payload -eq 'Folders')  { Invoke-FPFolders -DataSet $folders } }
		if ($installs) { if ($Payload -eq 'All' -or $Payload -eq 'Installs') { Invoke-FPChocoInstalls -DataSet $installs } }
		if ($removals) { if ($Payload -eq 'All' -or $Payload -eq 'Removals') { Invoke-FPChocoRemovals -DataSet $removals } }
		if ($regkeys)  { if ($Payload -eq 'All' -or $Payload -eq 'Registry') { Invoke-FPRegistry -DataSet $regkeys } }
		if ($services) { if ($Payload -eq 'All' -or $Payload -eq 'Services') { Invoke-FPServices -DataSet $services } }
		if ($files)    { if ($Payload -eq 'All' -or $Payload -eq 'Files')    { Invoke-FPFiles -DataSet $files } }
	}
}

function Set-FPConfiguration {
	param ()
	Write-Host "Configuring FudgePack scheduled task"
	Write-FudgePackLog -Category "Info" -Message "updating fudgepack client configuration"
	$filePath = "$($env:PROGRAMDATA)\FudgePack\Invoke-FudgePack.ps1"
	if (Test-Path $filepath) {
		$action = "powershell.exe -ExecutionPolicy ByPass -File $filepath"
		SCHTASKS /Create /RU "SYSTEM" /SC hourly /MO 1 /TN "Run FudgePack" /TR $action
		if (Get-ScheduledTask -TaskName "Run FudgePack" -ErrorAction SilentlyContinue) {
			Write-Output $True
		}
	}
}

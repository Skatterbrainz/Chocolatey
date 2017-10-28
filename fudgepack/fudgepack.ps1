#requires -version 3
<#
.SYNOPSIS
	Run Chocolatey package assignments using XML config file
.PARAMETER ControlFile
.PARAMETER LogFile
.PARAMETER TestMode
.NOTES
.EXAMPLE
	
	fudgepack.ps1 -Verbose

.EXAMPLE

	fudgepack.ps1 -ControlFile "\\server\share\
#>
param (
    [parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [string] $ControlFile = 'https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/fudgepack/appcontrol.xml',
    [parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [string] $LogFile = "$($env:TEMP)\fudgepack.log",
    [parameter(Mandatory=$False)]
        [switch] $TestMode
)

function Write-FPLog {
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
    }
}

$error.Clear()

if (-not(Test-Path "$($env:ProgramData)\chocolatey\choco.exe" )) {
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

if ($controlfile.StartsWith("http")) {
    try {
        [xml]$controldata = Invoke-RestMethod -Uri $controlfile
#        Write-Output $controldata
    }
    catch {
        Write-FPLog -Category "Error" -Message "failed to import data from Uri: $controlfile"
    }
}
if ($controldata) {
    $installs = $controldata.configuration.deployments.deployment | Where-Object {$_.enabled -eq "true" -and $_.device -eq $env:COMPUTERNAME}
    $removals = $controldata.configuration.removals.removal | Where-Object {$_.enabled -eq "true" -and $_.device -eq $env:COMPUTERNAME}
	Write-FPLog -Category "Info" -Message "--------- installaation assignments ---------"
    if ($installs) {
        $devicename = $installs.device
		$runtime    = $installs.when
        $autoupdate = $installs.autoupdate
        $username   = $installs.user
        $extparams  = $installs.params
        Write-FPLog -Category "Info" -Message "installations have been assigned to this computer"
        Write-FPLog -Category "Info" -Message "assigned device: $devicename"
		Write-FPLog -Category "Info" -Message "assigned runtime: $runtime"
        if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
            Write-FPLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $installs.InnerText -split ','
            foreach ($pkg in $pkglist) {
                if ($extparams.length -gt 0) {
                    Write-FPLog -Category "Info" -Message "package: $pkg (params: $extparams)"
                    if (-not $TestMode) {
                        choco install $pkg $extparams
                    }
                    else {
                        Write-Verbose "TEST MODE : $pkg"
                    }
                }
                else {
                    Write-FPLog -Category "Info" -Message "package: $pkg"
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
            Write-FPLog -Category "Info" -Message "skip: not yet time to run this assignment"
        }
    }
    else {
        Write-FPLog -Category "Info" -Message "NO installations have been assigned to this computer"
    }
	Write-FPLog -Category "Info" -Message "--------- removal assignments ---------"
    if ($removals) {
        $devicename = $removals.device
		$runtime    = $removals.when
        $username   = $removals.user
        $extparams  = $removals.params
        Write-FPLog -Category "Info" -Message "removals have been assigned to this computer"
		Write-FPLog -Category "Info" -Message "assigned device: $devicename"
        Write-FPLog -Category "Info" -Message "assigned runtime: $runtime"
        if ($runtime -eq 'now' -or (Get-Date).ToLocalTime() -ge $runtime) {
            Write-FPLog -Category "Info" -Message "run: runtime is now or already passed"
			$pkglist = $removals.InnerText -split ','
            foreach ($pkg in $pkglist) {
                if ($extparams.length -gt 0) {
                    Write-FPLog -Category "Info" -Message "package: $pkg (params: $extparams)"
                    if (-not $TestMode) {
                        choco uninstall $pkg $extparams
                    }
                    else {
                        Write-Verbose "TEST MODE : $pkg"
                    }
                }
                else {
                    Write-FPLog -Category "Info" -Message "package: $pkg"
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
            Write-FPLog -Category "Info" -Message "skip: not yet time to run this assignment"
        }
    }
    else {
        Write-FPLog -Category "Info" -Message "NO removals have been assigned to this computer"
    }
}
Write-FPLog -Category "Info" -Message "---- processing cycle finished ----"
if ($error.Count -eq 0) {
	Write-Output 0
}
else {
	Write-Output -1
}

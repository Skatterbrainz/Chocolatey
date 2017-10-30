#requires -RunAsAdministrator
#requires -version 3
<#
.SYNOPSIS
	Prompt for inputs to change scheduled task configuration
#>

function Configure-FudgePop {
	[CmdletBinding()]
	param ()
	try {
		$st = Get-ScheduledTask -TaskName "Run FudgePop" -ErrorAction SilentlyContinue
		if ($st) {
			$tr = $st.Triggers
			$rt = $tr[0].Repetition.Interval # returns PTxH where x = number of hours
			$xx = $rt.Substring(2,1)
			Write-Host "current hourly interval is set to: $xx"
		}
	}
	catch {}
	[int]$yy = (Read-Host -Prompt 'Schedule interval in hours [1 to 12] <1> ')
	if (-not $yy) {$yy = 1}
	Write-Verbose "you entered: $yy"
	if (($yy -ge 1) -and ($yy -le 12)) {
		Set-FPConfiguration -IntervalHours $yy
		[string]$choice = (Read-Host -Prompt 'Do you want to run the task now? <Y/N>: ')
		if ($choice -eq 'Y') {
			SCHTASKS /Run /TN "Run FudgePop"
		}
	}
	else {
		Write-Warning "Invalid interval value entered. Must be between 1 and 12"
	}
	try {
		$logsize = Get-ItemProperty -Path "HKLM:\SOFTWARE\FudgePop" -Name "MaxLogSizeMB" -ErrorAction SilentlyContinue | Select -ExpandProperty MaxLogSizeMB
		$xx = (Read-Host -Prompt 'Maximum log file size in MB [$logsize]')
		if ($xx -eq $null -or $xx -eq '') { $xx = $logsize }
		Set-ItemProperty -Path "HKLM:\SOFTWARE\FudgePop" -Name "MaxLogSizeMB" -Value $xx
	}
	catch {
		$xx = (Read-Host -Prompt 'Maximum log file size in MB [10]')
		if ($xx -eq $null -or $xx -eq '') { $xx = 10 }
		Set-ItemProperty -Path "HKLM:\SOFTWARE\FudgePop" -Name "MaxLogSizeMB" -Value $xx
	}
}

<# 
.SYNOPSIS
  Upgrade local chocolatey packages if network connection is found

.NOTES
  Place shortcut to script in Start Menu / Startup, or 
  create On-Login scheduled task, etc.
  
  Author: David Stein
  Date Created: 06/05/2017
#>

if (Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}) {
	Write-Host "Active network connection verified" -ForegroundColor Green 
	$choice = Read-Host `n "Update Chocolatey packages now [Y/N]"
	if ($choice -eq 'Y') {
		choco upgrade all -y
		Write-Host "Packages have been updated." -ForegroundColor Green
	}
	Write-Output "Completed."
}
else {
	Write-Output "No active network connection found."
}

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
	}
}

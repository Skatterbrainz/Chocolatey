# FudgePop (Module) 1.0.0

Centrally manage Windows 10 computers using a local script which reads instructions from a remote XML control file.

* Install, Upgrade and Remove Chocolatey Packages
* Create, Delete and Empty Folders
* Copy, Rename, Move or Delete Files
* Start, Stop and Reconfigure Services
* Add, Modify, Delete Shortcuts
* Add, Modify Registry Keys and Values
* Coming Soon: Deploy on-prem software

# Installation

  1. Use the Install-Module cmdlet to install FudgePop: **Install-Module FudgePop**
  2. Manually verify configuration: execute the **Invoke-FudgePop** function (recommend -Verbose for first time use)
  3. Configure the scheduled task using the **Set-FudgePopConfiguration** function
  4. Confirm the scheduled task configuration and manually run the task to insure proper operation

# Functions

## Invoke-FudgePop

* **ControlFile** _path-or-uri_

Path or URI to control XML file.  The default is https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/FudgePop/control.xml
For more information about the XML syntax, refer to [ControlFileSyntax](https://github.com/Skatterbrainz/Chocolatey/blob/master/FudgePop/ControlFileSyntax.md)

* **LogFile** _string_

Optional path and filename for FudgePop client log. Default is $env:TEMP\fudgepop.log
Note that $env:TEMP refers to the account which runs the script.  If script is set to run in a scheduled task
under the local SYSTEM account, the temp will be related to that account.

* **Payload** _string_

Optional sub-group of XML control settings to apply.  The options are 'All','Installs','Removals','Folders','Files','Registry', and 'Services'.  The default is 'All'

* **Configure**

Switch. Invokes the scheduled task setup using default values.  To specify custom values, use the **Set-FudgePopConfiguration** function.

## Set-FudgePopConfiguration

Prompts for input to control FudgePop client settings.

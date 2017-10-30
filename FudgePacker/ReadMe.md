# FudgePacker (Module) 0.8.8

Centrally manage Windows 10 computers using a local script which reads instructions from a remote XML control file.

## Invoke-FudgePack

* **ControlFile** _path-or-uri_

Path or URI to control XML file.  The default is https://raw.githubusercontent.com/Skatterbrainz/Chocolatey/master/control.xml

* **LogFile** _string_

Optional path and filename for FudgePack client log. Default is $env:TEMP\fudgepack.log
Note that $env:TEMP refers to the account which runs the script.  If script is set to run in a scheduled task
under the local SYSTEM account, the temp will be related to that account.

* **Payload** _string_

Optional sub-group of XML control settings to apply.  The options are 'All','Installs','Removals','Folders','Files','Registry', and 'Services'.  The default is 'All'

* **Configure**

Switch. Invokes the scheduled task setup using default values.  To specify custom values, use the Configure-FudgePack function.

## Configure-FudgePack

Prompts for input to control FudgePack client settings.

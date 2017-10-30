# FudgePop Control File Syntax

## Overview

The control XML format includes a set of basic sections which focus on specific areas of Windows device management:

* Control (global settings)
* Deployments (Install/Update Chocolatey packages)
* Removals (Uninstall Chocolatey packages)
* Files
* Folders
* Registry Keys
* Services
* Shortcuts
* On-Prem Applications

The default location of the control is on this Github repo.  The file can be copied, renamed, and located anywhere which is accessible to the devices being configured to be managed by FudgePop.  For example, if the control.xml file is copied to a public-facing (e.g. DMZ) server share or web host, the Invoke-FudgePop function needs to include the -ControlFile parameter to specify the desired location.  For example: Invoke-FudgePop -ControlFile "https://contoso.xyz/fudgepop/custom.xml"

## Syntactical Parameterization Constructs

(boy, that sounds impressive)

**Control**

* Description: provides global settings for all devices and all operations included with FudgePop
* Required:
  * enabled = "true" or "false" ("false" = kill switch / disables FudgePop)
* Optional:
  * exclude = "name" (name of computers to disable FudgePop operations)

**Installs**

* Description: Install and Update Chocolatey Packages
* Element: /configuration/deployments/deployment
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * when = "now" or "MM/DD/YYYY HH:MM AM/PM" (example: "10/27/2017 10:30 PM")
  * innerText = names of Chocolatey packages, comma-separated (example: "7zip,vlc,office365proplus")
* Optional: 
  * user = "name" or "all"

**Removals**

* Description: Remove Chocolatey Packages
* Element: /configuration/removals/removal
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * when = "now" or "MM/DD/YYYY HH:MM AM/PM" (example: "10/27/2017 10:30 PM")
* Optional: 
  * user = "name" or "all"

**Shortcut**

* Description: Configure and Manage Shortcuts
* Element: /configuration/shortcuts/shortcut
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * name = "_name-of-shortcut_"
  * type = "lnk" or "url"
  * action = "create" or "delete"
  * target = "_target-path-or-url_"
  * path = "_where-to-create-the-shortcut_"
* Optional:
  * description = "_string_" (only applies to lnk shortcuts)
  * windowstyle = "normal", "max" or "min"
  * args = "_string_"
  * workingpath = "_string-path_"
* Notes:
  * The path value can be an explicit path, an environment reference (e.g. $env:PUBLIC) or a SpecialFolders enum
  * for a list of SpecialFolder enums, refer to [MSDN](https://msdn.microsoft.com/en-us/library/system.environment.specialfolder.aspx)
  
**Files**

* Description: Configure and Manage Files
* Element: /configuration/files/file
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * action = "download","copy","move","rename","delete"
  * source = "_path_"
  * target = "_path_"
* Optional: 
  * (none)

**Folders**

* Description: Configure and Manage Folders
* Element: /configuration/folders/folder
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * action = "create","empty","rename","delete"
* Optional: 
  * (none)
  
**Services**

* Description: Configure and Manage Windows Services
* Element: /configuration/services/service
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * action = "modify", "start", "stop" or "restart"
  * name = "_name_"
* Optional:
  * config = "_parameters_" (example: "startup=automatic", "startup=disabled")
  
**OPApps**

* Description: Install or Remove apps using on-premises content sourcing
* Element: /configuration/opapps/opapp
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * run = "_path-and-filename_" (example: "\\fs1\apps\packages\app\setup.exe")
  * platforms = "name,name,..." (example: "win10x64,win7x64,win7x86")
* Optional:
  * params = "_parameters_" (example: "/S")

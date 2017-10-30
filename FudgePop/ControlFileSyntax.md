# FudgePop Control File Syntax

## Overview

The control XML format includes a set of basic sections which focus on specific areas of Windows device management:

* Applications (Chocolatey packages, and On-prem applications)
* Files and Folders
* Registry Keys
* Services
* Shortcuts

## Syntactical Parameterization Constructs

(boy, that sounds impressive)

**Ccontrol**

* provides global settings for all devices and all operations included with FudgePop
* Required:
  * enabled="true" or "false" ("false" disables FudgePop)

**Installs**

* Element: /configuration/deployments/deployment
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * when = "now" or "MM/DD/YYYY HH:MM AM/PM" (example: "10/27/2017 10:30 PM")
  * innerText = names of Chocolatey packages, comma-separated (example: "7zip,vlc,office365proplus")
* Optional: 
  * user = "name" or "all"

**Removals**

* Element: /configuration/removals/removal
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * when = "now" or "MM/DD/YYYY HH:MM AM/PM" (example: "10/27/2017 10:30 PM")
* Optional: 
  * user = "name" or "all"

**Shortcut**

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
  
**Files**

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

* Element: /configuration/folders/folder
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * action = "create","empty","rename","delete"
* Optional: 
  * (none)
  
**Services**

* Element: /configuration/services/service
* Required:
  * device = "name" or "all"
  * enabled = "true" or "false"
  * action = "modify", "start", "stop" or "restart"
  * name = "_name_"
* Optional:
  * config = "_parameters_" (example: "startup=automatic", "startup=disabled")
  
* Optional: 

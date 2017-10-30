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

**Installs**

* Element: /configuration/deployments/deployment
* Required:
* Optional: 

**Removals**

* Element: /configuration/removals/removal
* Required:
* Optional: 

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
* Optional: 

**Folders**

* Element: /configuration/folders/folder
* Required:
* Optional: 

**Services**

* Element: /configuration/services/service
* Required:
* Optional: 

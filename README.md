# PSYaml

## Build Status

|Branch | Status |
|-------|:--------:|
|Master |[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/pezhore/PSYaml?branch=master&svg=true)](https://ci.appveyor.com/project/pezhore/PSYaml/branch/master)|

<img src=".\Media\YAML_PS.png" height="200" align="right" />

## Introduction
This module will help users convert from/to YAML. For more information see [the documentation](./Documentation.adoc).

Please note that the **Master** branch has the latest, ready-for-production version. The **release/stage** branch is the holding ground for master merges where integration testing will take place. Other branches with active development will be denoted by having a prefix ( **feature/**, **bugfix/**, **release/**, etc) followed by an unique identifier. Nothing is merged into **release/stage** branch without code review, and only code that passes testing in the **release/stage** branch will be merged into **master**.

## Features
* Fancy Logo
* Bundled binary 

## ToDo
* Add automatic testing of all public functions

## Example Usage
```PowerShell
import-module psyaml
$yaml = @"
anArray:
- 1
- 2
- 3
nested:
  array:
  - this
  - is
  - an
  - array
hello: world
"@
$YamlObject = ConvertFrom-YAML $yamlString
ConvertTo-YAML $YamlObject
```

## Contact Information
Author: Phil-Factor, Brian Marsh

## Release Notes
|  Version  | Change Log                                                        |
| :-------: | ----------------------------------------------------------------- |
|  1.0.1.1  | Reformated several sections for readability, added pester tests   |
|  1.0.1    | Converted single psm1 file to multiple public/private functions   |

## Installation
### One time setup
* Download/clone the repository
* Copy the PSYaml folder to a module path (e.g. `$env:USERPROFILE\Documents\WindowsPowerShell\Modules\`)
* Alternatively, in the PS-PSYaml folder use PSDeploy (`Invoke-PSDeploy -Path .\PSDeploy\`)

### Automated Install
* Assuming you have PowerShell v5 and a Nuget Repository configured, use the built in Module management (`Install-Module PSYaml`)

## Import the module.
`Import-Module PSYaml    #Alternatively, Import-Module \\Path\To\PSYaml`

## Get commands in the module
`Get-Command -Module PSYaml`

## Get help
`Get-Help ConvertFrom-Yaml -Full`
`Get-Help about_PSYaml`



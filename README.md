# PSYaml

# Build Status

|Branch | Status |
|-------|:--------:|
|Master |[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/pezhore/PSYaml?branch=master&svg=true)](https://ci.appveyor.com/project/pezhore/PSYaml/branch/master)|

<img src=".\Media\YAML_PS.png" height="200" align="right" />

# Introduction
This module will help users convert from/to YAML. For more information see [the documentation](./Documentation.md) or the [legacy documentation](./Legacy_Documentation.adoc).

Please note that the **Master** branch has the latest, ready-for-production version. The **release/stage** branch is the holding ground for master merges where integration testing will take place. Other branches with active development will be denoted by having a prefix ( **feature/**, **bugfix/**, **release/**, etc) followed by an unique identifier. Nothing is merged into **release/stage** branch without code review, and only code that passes testing in the **release/stage** branch will be merged into **master**.

# Features
* Fancy Logo
* Bundled binary
* Pester Testing

# ToDo
* Clean up documentation

## Example Usage
```PowerShell

# Ensure module is imported in the current Powershell session
# Import-Module FXPSYaml (PSGallery) - Use it if you have installed from PSGallery.
# Import-Module <path_to_PSYaml_folder>\PSYaml.psm1 (local) - Use it if you have installed it locally.

# Converting from yaml to Powershell
$yamlString = @"
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
key: value
"@

$yamlString | ConvertFrom-YAML

# Converting from a Powershell hashtable to Yaml.
$hashtable = @{anArray = 1, 2, 3; nested = @{array = 1, 2, 3}; key = "value"}
$hashtable | ConvertTo-Yaml
```

## Contact Information
Author: Phil-Factor (philipFactor@gmail.com)

## Release Notes
|  Version  | Change Log                                                        |
| :-------: | ----------------------------------------------------------------- |
|  1.0.3    | Closed the open YAML file if error occurs in it during parsing    |
|  1.0.2    | Reformated several sections for readability, added pester tests   |
|  1.0.1    | Converted single psm1 file to multiple public/private functions   |

# Installation
### PSGallery Install
`Requires Powershell V5`
```powershell
# [Optional] Ensure PowershellGet package provider is up to date
# Install-Module -Name PowerShellGet -Repository PSGallery -Force

# Install and Import module from PSGallery
Install-Module FXPSYaml -Force
Import-Module FXPSYaml
```
### Local Install
```powershell
# Install / Import PSDeploy module first
Install-Module PSDeploy
Import-Module PSDeploy

# Run PSDeploy
PSDeploy <path_to_PSDeploy_folder>\PSYaml.PSDeploy.ps1

# Import PSYaml
Import-Module <path_to_PSYaml_folder>\PSYaml.psm1
```
# List module commands
```powershell
Get-Command -Module PSYaml
```
# Get help
> Use PSYaml instead FXPSYaml if you have installed it using Local install method
```powershell
# Get full help of all module commands
get-command -Module FXPSYaml | select -ExpandProperty name | ForEach-Object {write-host "$_" -BackgroundColor "red"; Get-Help $_ -full}
```

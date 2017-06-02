<img src=".\Media\YAML_PS.svg" height="200" align="right" />

# PSYaml

# Introduction
This module will help users convert from/to YAML. 

``` Language-PowerShell
import-module psyaml
$yamlString =@"
    invoice: !!str 34843
    date   : 2001-01-23
    approved: yes
    bill-to: 
        given  : Chris
        family : Dumars
        address:
            lines: |
                458 Walkman Dr.
                Suite #292
            city    : Royal Oak
            state   : MI
            postal  : 48046
    ship-to: id001
    product:
        - sku         : BL394D
            quantity    : 4
            description : Basketball
            price       : 450.00
        - sku         : BL4438H
            quantity    : 1
            description : Super Hoop
            price       : 2392.00
    tax  : 251.42
    total: 4443.52
    comments: >
        Late afternoon is best.
        Backup contact is Nancy
        Billsmer @ 338-4338.

"@
$YamlObject = ConvertFrom-YAML $yamlString
ConvertTo-YAML $YamlObject
```

Please note that the **Master** branch has the latest, ready-for-production version. The **release/stage** branch is the holding ground for master merges where integration testing will take place. Other branches with active development will be denoted by having a prefix ( **feature/**, **bugfix/**, **release/**, etc) followed by an unique identifier. Nothing is merged into **release/stage** branch without code review, and only code that passes testing in the **release/stage** branch will be merged into **master**.

## Features
* Fancy Graphics
* Bundled binary 

## ToDo
* Add automatic testing of all public functions

## Contact Information
Author: Phil-Factor, Brian Marsh

## Release Notes
|  Version  | Change Log                                                        |
| :-------: | ----------------------------------------------------------------- |
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



# This module's name
$ModuleName = "PSYaml"

# Get this instance of PowerShell's major version
$PSVersion = $PSVersionTable.PSVersion.Major

#Force Import this repo's module
Import-Module "$($PSScriptRoot)\..\$($ModuleName)\$($ModuleName).psm1" -Force
$libPath = "$($PSScriptRoot)\..\$($ModuleName)\lib\YamlDotNet.dll"
Add-Type -Path $libPath

$Helpers = @( Get-ChildItem -Path $PSScriptRoot\Helpers\*.ps1 -ErrorAction SilentlyContinue )
Foreach ($Helper in $Helpers)
{
    Try
    {
        . $Helper.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($Helper.fullname): $_"
    }
}

$YamlText = @"
  anArray:
  - 1
  - 2
  - 3
  nested:
    array:
    - 'this'
    - 'is'
    - 'an'
    - 'array'
  hello: 'world'
"@

$JsonText = '{"anArray": ["1", "2", "3"], "nested": {"array": ["this", "is", "an", "array"]}, "hello": "world"}'

if ($PSVersion -ne 5)
{
    Describe "Should convert YAML to JSON in PowerShell v$($PSVersion)" {
        BeforeEach {
            Remove-Variable -Name obj1, obj2 -ErrorAction SilentlyContinue
        }
        Context 'Strict mode' {

            Set-StrictMode -Version $PSversion

            It 'Should convert yaml to json' {
                $obj1 = Convert-PSObjectToHashtable -InputObject (ConvertFrom-Json -InputObject $JsonText)
                $obj2 = Convert-PSObjectToHashtable -InputObject (Convert-YamlToJson -YamlString $YamlText | ConvertFrom-Json)
                
                $obj1 | Should match $obj2

            }
        }
    }
}

Describe "Should convert YAML to JSON in PowerShell v5" {
    BeforeEach {
            Remove-Variable -Name obj1, obj2 -ErrorAction SilentlyContinue
    }

    Context 'Strict mode' {

        Set-StrictMode -Version 5

        It 'Should convert yaml to json' {
            $obj1 = Convert-PSObjectToHashtable -InputObject (ConvertFrom-Json -InputObject $JsonText)
            $obj2 = Convert-PSObjectToHashtable -InputObject (Convert-YamlToJson -YamlString $YamlText | ConvertFrom-Json)
            $obj1 | Should match $obj2

        }
    }
}

Describe "Should convert YAML to JSON in PowerShell v4" {
    BeforeEach {
            Remove-Variable -Name obj1, obj2 -ErrorAction SilentlyContinue
    }

    Context 'Strict mode' {

        Set-StrictMode -Version 4

        It 'Should convert yaml to json' {
            $obj1 = Convert-PSObjectToHashtable -InputObject (ConvertFrom-Json -InputObject $JsonText)
            $obj2 = Convert-PSObjectToHashtable -InputObject (Convert-YamlToJson -YamlString $YamlText | ConvertFrom-Json)
            $obj1 | Should match $obj2

        }
    }
}

Describe "Should convert YAML to JSON in PowerShell v3" {
    BeforeEach {
            Remove-Variable -Name obj1, obj2 -ErrorAction SilentlyContinue
    }

    Context 'Strict mode' {

        Set-StrictMode -Version 3

        It 'Should convert yaml to json' {
            $obj1 = Convert-PSObjectToHashtable -InputObject (ConvertFrom-Json -InputObject $JsonText)
            $obj2 = Convert-PSObjectToHashtable -InputObject (Convert-YamlToJson -YamlString $YamlText | ConvertFrom-Json)
            $obj1 | Should match $obj2

        }
    }
}

Describe "Should convert YAML to JSON in PowerShell v2" {
    BeforeEach {
            Remove-Variable -Name obj1, obj2 -ErrorAction SilentlyContinue
    }

    Context 'Strict mode' {

        Set-StrictMode -Version 2

        It 'Should convert yaml to json' {
            $obj1 = Convert-PSObjectToHashtable -InputObject (ConvertFrom-Json -InputObject $JsonText)
            $obj2 = Convert-PSObjectToHashtable -InputObject (Convert-YamlToJson -YamlString $YamlText | ConvertFrom-Json)
            $obj1 | Should match $obj2

        }
    }
}
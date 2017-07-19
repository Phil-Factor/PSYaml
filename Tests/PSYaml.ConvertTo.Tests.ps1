# This module's name
$ModuleName = "PSYaml"

# Get this instance of PowerShell's major version
$PSVersion = $PSVersionTable.PSVersion.Major

#Force Import this repo's module
Import-Module "$($PSScriptRoot)\..\$($ModuleName)\$($ModuleName).psm1" -Force
$libPath = "$($PSScriptRoot)\..\$($ModuleName)\lib\YamlDotNet.dll"
Add-Type -Path $libPath

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

$PSObj = ConvertFrom-Yaml $YamlText

if ($PSVersion -ne 5)
{
    Describe "Should convert a PSObject to YAML in PowerShell v$($PSVersion)" {
        BeforeEach {
            Remove-Variable -Name Yaml, ConvertedObj -ErrorAction SilentlyContinue
            
            $Yaml = ConvertTo-Yaml $PSObj
            
        }

        Context 'Strict mode' {

            Set-StrictMode -Version $PSversion

            It 'Should convert yaml back to PSObject' {
                $ConvertedObj = ConvertFrom-Yaml $Yaml
                $Output = Foreach ($Key in $PSObj.Keys)
                {
                    Compare-Object $ConvertedObj.$Key $PSObj.$Key
                }

                $Output | Should be $null
            }
        }
    }
}

Describe "Should convert a PSObject to YAML in PowerShell v5" {
    BeforeEach {
            Remove-Variable -Name Yaml, ConvertedObj -ErrorAction SilentlyContinue
            
            $Yaml = ConvertTo-Yaml $PSObj
        }

    Context 'Strict mode' {

        Set-StrictMode -Version 5

        It 'Should convert yaml back to PSObject' {
            $ConvertedObj = ConvertFrom-Yaml $Yaml
            $Output = Foreach ($Key in $PSObj.Keys)
            {
                Compare-Object $ConvertedObj.$Key $PSObj.$Key
            }

            $Output | Should be $null
        }
    }
}

Describe "Should convert a PSObject to YAML in PowerShell v4" {
    BeforeEach {
            Remove-Variable -Name Yaml, ConvertedObj -ErrorAction SilentlyContinue
            
            $Yaml = ConvertTo-Yaml $PSObj
        }

    Context 'Strict mode' {

        Set-StrictMode -Version 4

        It 'Should convert yaml back to PSObject' {
            $ConvertedObj = ConvertFrom-Yaml $Yaml
            $Output = Foreach ($Key in $PSObj.Keys)
            {
                Compare-Object $ConvertedObj.$Key $PSObj.$Key
            }

            $Output | Should be $null
        }
    }
}

Describe "Should convert a PSObject to YAML in PowerShell v3" {
    BeforeEach {
            Remove-Variable -Name Yaml, ConvertedObj -ErrorAction SilentlyContinue
            
            $Yaml = ConvertTo-Yaml $PSObj
        }

    Context 'Strict mode' {

        Set-StrictMode -Version 3

        It 'Should convert yaml back to PSObject' {
            $ConvertedObj = ConvertFrom-Yaml $Yaml
            $Output = Foreach ($Key in $PSObj.Keys)
            {
                Compare-Object $ConvertedObj.$Key $PSObj.$Key
            }

            $Output | Should be $null
        }
    }
}

Describe "Should convert a PSObject to YAML in PowerShell v2" {
    BeforeEach {
            Remove-Variable -Name Yaml, ConvertedObj -ErrorAction SilentlyContinue
            
            $Yaml = ConvertTo-Yaml $PSObj
        }

    Context 'Strict mode' {

        Set-StrictMode -Version 2

        It 'Should convert yaml back to PSObject' {
            $ConvertedObj = ConvertFrom-Yaml $Yaml
            $Output = Foreach ($Key in $PSObj.Keys)
            {
                Compare-Object $ConvertedObj.$Key $PSObj.$Key
            }

            $Output | Should be $null
        }
    }
}
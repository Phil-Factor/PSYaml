# This module's name
$ModuleName = "PSYaml"

# Get this instance of PowerShell's major version
$PSVersion = $PSVersionTable.PSVersion.Major

#Force Import this repo's module
Import-Module $PSScriptRoot\..\$ModuleName\$ModuleName.psm1 -Force

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

if ($PSVersion -ne 5)
{
    Describe "Should convert YAML to a PSObject in PowerShell v$($PSVersion)" {
        BeforeEach {
            Remove-Variable -Name PSObj -ErrorAction SilentlyContinue

            $PSObj = ConvertFrom-Yaml $yaml
        }

        Context 'Strict mode' {

            Set-StrictMode -Version $PSversion

            It 'Should have three keys' {
                $Keys = @('anArray','nested','hello')
                $PSObj.Keys | ForEach-Object { $Keys -contains $_ } | Should be $True, $True, $true
            }

            It 'Should have a nested array with length 4' {
                $PSobj.nested.array.Length | Should be 4
            }

            It 'Should have a key/value hello world' {
                $PSobj.hello | Should be 'world'
            }
        }
    }
}

Describe "Should convert YAML to a PSObject in PowerShell v5" {
    BeforeEach {
        Remove-Variable -Name PSObj -ErrorAction SilentlyContinue

        $PSObj = ConvertFrom-Yaml $yaml
    }

    Context 'Strict mode' {

        Set-StrictMode -Version 5

        It 'Should have three keys' {
            $Keys = @('anArray','nested','hello')
            $PSObj.Keys | ForEach-Object { $Keys -contains $_ } | Should be $True, $True, $true
        }

        It 'Should have a nested array with length 4' {
            $PSobj.nested.array.Length | Should be 4
        }

        It 'Should have a key/value hello world' {
            $PSobj.hello | Should be 'world'
        }
    }
}

Describe "Should convert YAML to a PSObject in PowerShell v4" {
    BeforeEach {
        Remove-Variable -Name PSObj -ErrorAction SilentlyContinue

        $PSObj = ConvertFrom-Yaml $yaml
    }

    Context 'Strict mode' {

        Set-StrictMode -Version 4

        It 'Should have three keys' {
            $Keys = @('anArray','nested','hello')
            $PSObj.Keys | ForEach-Object { $Keys -contains $_ } | Should be $True, $True, $true
        }

        It 'Should have a nested array with length 4' {
            $PSobj.nested.array.Length | Should be 4
        }

        It 'Should have a key/value hello world' {
            $PSobj.hello | Should be 'world'
        }
    }
}

Describe "Should convert YAML to a PSObject in PowerShell v3" {
    BeforeEach {
        Remove-Variable -Name PSObj -ErrorAction SilentlyContinue

        $PSObj = ConvertFrom-Yaml $yaml
    }

    Context 'Strict mode' {

        Set-StrictMode -Version 3

        It 'Should have three keys' {
            $Keys = @('anArray','nested','hello')
            $PSObj.Keys | ForEach-Object { $Keys -contains $_ } | Should be $True, $True, $true
        }

        It 'Should have a nested array with length 4' {
            $PSobj.nested.array.Length | Should be 4
        }

        It 'Should have a key/value hello world' {
            $PSobj.hello | Should be 'world'
        }
    }
}

Describe "Should convert YAML to a PSObject in PowerShell v2" {
    BeforeEach {
        Remove-Variable -Name PSObj -ErrorAction SilentlyContinue

        $PSObj = ConvertFrom-Yaml $yaml
    }

    Context 'Strict mode' {

        Set-StrictMode -Version 2

        It 'Should have three keys' {
            $Keys = @('anArray','nested','hello')
            $PSObj.Keys | ForEach-Object { $Keys -contains $_ } | Should be $True, $True, $true
        }

        It 'Should have a nested array with length 4' {
            $PSobj.nested.array.Length | Should be 4
        }

        It 'Should have a key/value hello world' {
            $PSobj.hello | Should be 'world'
        }
    }
}
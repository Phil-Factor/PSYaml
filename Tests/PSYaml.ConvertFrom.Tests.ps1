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

Describe "Should convert YAML to a PSObject" {
    BeforeEach {
        Remove-Variable -Name PSObj -ErrorAction SilentlyContinue

        $PSObj = ConvertFrom-Yaml $yaml
    }

    Context 'Strict mode' {

        Set-StrictMode -Version latest

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
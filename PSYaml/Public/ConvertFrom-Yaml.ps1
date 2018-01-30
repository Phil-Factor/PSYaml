function ConvertFrom-Yaml {

    <#
    .SYNOPSIS
        Converts YAML files into PowerShell objects.

    .DESCRIPTION
        Converts YAML files into PowerShell objects. Can be invoked either directly from Array String or File Path.
        Parameters are mutually exclusive.

    .PARAMETER YamlString
        Converts YAML string into PowerShell Array.

    .PARAMETER Path
        Converts YAML file into PowerShell Array.

    .EXAMPLE
        ConvertFrom-Yaml -Path C:\test.yaml

    .EXAMPLE
        @(get-content -Path C:\test.yaml) | ConvertFrom-Yaml

    .LINK
        https://github.com/RamblingCookieMonster/PSDeploy/blob/master/PSDeploy/Private/PSYaml/Private/YamlDotNet-Integration.ps1

    .NOTES
        Link above shows where I got the file import from.

    #>
    [CmdletBinding()]
    param
    (
    [parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    $YamlString,
    [parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
    $Path
    )
BEGIN { }
PROCESS
    {
        If($Path){
            $streamReader = [System.IO.File]::OpenText($Path)
            $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
            $yamlStream.Load([System.IO.TextReader]$streamReader)
            ConvertFrom-YAMLDocument ($yamlStream.Documents[0])
        }
        Else{
            $stringReader = new-object System.IO.StringReader([string]$yamlString)
            $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
            $yamlStream.Load([System.IO.TextReader]$stringReader)
            ConvertFrom-YAMLDocument ($yamlStream.Documents[0])
        }
    }
END {}
}
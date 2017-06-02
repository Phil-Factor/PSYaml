function ConvertFrom-Yaml
    {
    [CmdletBinding()]
    param
    (
    [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    $YamlString
    )
BEGIN { }
PROCESS
    {$stringReader = new-object System.IO.StringReader([string]$yamlString)
    $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
    $yamlStream.Load([System.IO.TextReader]$stringReader)
    ConvertFrom-YAMLDocument ($yamlStream.Documents[0])}
END {}
}
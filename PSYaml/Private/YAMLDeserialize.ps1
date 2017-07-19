Function YAMLDeserialize

    {
    [CmdletBinding()]
    param
    (
        $YamlString
    )
$stringReader = new-object System.IO.StringReader([string]$yamlString)
$Deserializer=New-Object -TypeName YamlDotNet.Serialization.Deserializer -ArgumentList $null, $null, $false
$Deserializer.Deserialize([System.IO.TextReader]$stringReader)
}
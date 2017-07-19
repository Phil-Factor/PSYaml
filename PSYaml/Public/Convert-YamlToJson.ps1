Function Convert-YamlToJson
    {
    param
    (
    [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    $YamlString
    )
BEGIN { }
PROCESS
    {$stringReader = new-object System.IO.StringReader([string]$yamlString)
    $Deserializer = New-Object -TypeName YamlDotNet.Serialization.Deserializer -ArgumentList $null, $null, $false
    $netObject = $Deserializer.Deserialize([System.IO.TextReader]$stringReader)
    $Serializer = New-Object YamlDotNet.Serialization.Serializer([YamlDotNet.Serialization.SerializationOptions]::JsonCompatible)
    #None. Roundtrip, DisableAliases, EmitDefaults, JsonCompatible, DefaultToStaticType
    $stringBuilder = New-Object System.Text.StringBuilder
    $stream = New-Object System.io.StringWriter -ArgumentList $stringBuilder
    $Serializer.Serialize($stream, $netObject) #
    $stream.ToString()}
END {}
}
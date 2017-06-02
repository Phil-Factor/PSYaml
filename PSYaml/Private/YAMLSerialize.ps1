Function YAMLSerialize
    {
    [CmdletBinding()]
    param
    (
    [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [object]$PowershellObject
    )
BEGIN { }
PROCESS
    {$Serializer = New-Object YamlDotNet.Serialization.Serializer([YamlDotNet.Serialization.SerializationOptions]::emitDefaults)
#None. Roundtrip, DisableAliases, EmitDefaults, JsonCompatible, DefaultToStaticType
$stringBuilder = New-Object System.Text.StringBuilder
$stream = New-Object System.io.StringWriter -ArgumentList $stringBuilder 
$Serializer.Serialize($stream,$PowershellObject) #System.IO.TextWriter writer, System.Object graph)
$stream.ToString()}
END {}
}
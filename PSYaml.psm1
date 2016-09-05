Add-Type -Path "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules\PSYaml\YAMLdotNet\YamlDotNet.3.8.0\lib\dotnet\yamldotnet.dll"


function ConvertTo-YAML
{
<#
 .SYNOPSIS
   creates a YAML description of the data in the object
 .DESCRIPTION
   This produces YAML from any object you pass to it. It isn't suitable for the huge objects produced by some of the cmdlets such as Get-Process, but fine for simple objects
 .EXAMPLE
   $array=@()
   $array+=Get-Process wi* |  Select-Object Handles,NPM,PM,WS,VM,CPU,Id,ProcessName 
   ConvertTo-YAML $array

 .PARAMETER Object 
   the object that you want scripted out
 .PARAMETER Depth
   The depth that you want your object scripted to
 .PARAMETER Nesting Level
   internal use only. required for formatting
#>
    
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        $inputObject,
        [parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
        [int]$depth = 16,
        [parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
        [int]$NestingLevel = 0,
        [parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
        [int]$XMLAsInnerXML = 0
    )
    
    BEGIN { }
    PROCESS
    {
        If ($inputObject -eq $Null) { $p += 'null'; return $p } # if it is null return null
        if ($NestingLevel -eq 0) { '---' }
        
        $padding = [string]'  ' * $NestingLevel # lets just create our left-padding for the block
        try
        {
            $Type = $inputObject.GetType().Name # we start by getting the object's type
            if ($Type -ieq 'Object[]') { $Type = "$($inputObject.GetType().BaseType.Name)" } #what it really is
            if ($depth -ilt $NestingLevel) { $Type = 'OutOfDepth' } #report the leaves in terms of object type
            elseif ($Type -ieq 'XmlDocument' -or $Type -ieq 'XmlElement')
            {
                if ($XMLAsInnerXML -ne 0) { $Type = 'InnerXML' }
                else
                { $Type = 'XML' }
            } # convert to PS Alias
            # prevent these values being identified as an object
            if (@('boolean', 'byte', 'char', 'datetime', 'decimal', 'double', 'float', 'single', 'guid', 'int', 'int32',
            'int16', 'long', 'int64', 'OutOfDepth', 'RuntimeType', 'PSNoteProperty', 'regex', 'sbyte', 'string',
            'timespan', 'uint16', 'uint32', 'uint64', 'uri', 'version', 'void', 'xml', 'datatable', 'Dictionary`2',
            'SqlDataReader', 'datarow', 'ScriptBlock', 'type') -notcontains $type)
            {
                if ($Type -ieq 'OrderedDictionary') { $Type = 'HashTable' }
                elseif ($Type -ieq 'PSCustomObject') { $Type = 'PSObject' } #
                elseif ($Type -ieq 'List`1') { $Type = 'Array' }
                elseif ($inputObject -is "Array") { $Type = 'Array' } # whatever it thinks it is called
                elseif ($inputObject -is "HashTable") { $Type = 'HashTable' } # for our purposes it is a hashtable
                elseif (($inputObject | gm -membertype Properties |
                Select name | Where name -like 'Keys') -ne $null) { $Type = 'generic' } #use dot notation
                elseif (($inputObject | gm -membertype Properties | Select name).count -gt 1) { $Type = 'Object' }
            }
            write-verbose "$($padding)Type:='$Type', Object type:=$($inputObject.GetType().Name), BaseName:=$($inputObject.GetType().BaseType.Name) "
            
            switch ($Type)
            {
                'ScriptBlock'{ "{$($inputObject.ToString())}" }
                'InnerXML'        { "|`r`n" + ($inputObject.OuterXMl.Split("`r`n") | foreach{ "$padding$_`r`n" }) }
                'DateTime'   { $inputObject.ToString('s') } # s=SortableDateTimePattern (based on ISO 8601) using local time
                'Boolean' {
                    "$(&{
                        if ($inputObject -eq $true) { 'true' }
                        Else { 'false' }
                    })"
                }
                'string' {
                    $String = "$inputObject"
                    if ($string -match '[\r\n]' -or $string.Length -gt 80)
                    {
                        # right, we have to format it to YAML spec.
                        ">`r`n" # signal that we are going to use the readable 'newlines-folded' format
                        $string.Split("`n") | foreach {
                            $bits = @(); $length = $_.Length; $IndexIntoString = 0; $wrap = 80
                            while ($length -gt $IndexIntoString + $Wrap)
                            {
                                $earliest = $_.Substring($IndexIntoString, $wrap).LastIndexOf(' ')
                                $latest = $_.Substring($IndexIntoString + $wrap).IndexOf(' ')
                                $BreakPoint = &{
                                    if ($earliest -gt ($wrap + $latest)) { $earliest }
                                    else { $wrap + $latest }
                                }
                                if ($earliest -lt (($BreakPoint * 10)/100)) { $BreakPoint = $wrap } # in case it is a string without spaces
                                $padding + $_.Substring($IndexIntoString, $BreakPoint).Trim() + "`r`n"
                                $IndexIntoString += $BreakPoint
                            }
                            if ($IndexIntoString -lt $length) { $padding + $_.Substring($IndexIntoString).Trim() + "`r`n" }
                            else { "`r`n" }
                        }
                    }
                    else { "'$($string -replace '''', '''''')'" }
                }
                'Char'     { "([int]$inputObject)" }
                {
                    @('byte', 'decimal', 'double', 'float', 'single', 'int', 'int32', 'int16', `
                    'long', 'int64', 'sbyte', 'uint16', 'uint32', 'uint64') -contains $_
                }
                { "$inputObject" } # rendered as is without single quotes
                'PSNoteProperty' { "$(ConvertTo-YAML -inputObject $inputObject.Value -depth $depth -NestingLevel ($NestingLevel + 1))" }
                'Array'    { "$($inputObject | ForEach { "`r`n$padding- $(ConvertTo-YAML -inputObject $_ -depth $depth -NestingLevel ($NestingLevel + 1))" })" }
                'HashTable'{
                    ("$($inputObject.GetEnumerator() | ForEach {
                        "`r`n$padding  $($_.Name): " +
                        (ConvertTo-YAML -inputObject $_.Value -depth $depth -NestingLevel ($NestingLevel + 1))
                    })")
                }
                'Dictionary`2'{
                    ("$($inputObject.GetEnumerator() | ForEach {
                        "`r`n$padding  $($_.Key): " +
                        (ConvertTo-YAML -inputObject $_.Value -depth $depth -NestingLevel ($NestingLevel + 1))
                    })")
                }
                'PSObject' { ("$($inputObject.PSObject.Properties | ForEach { "`r`n$padding $($_.Name): " + (ConvertTo-YAML -inputObject $_ -depth $depth -NestingLevel ($NestingLevel + 1)) })") }
                'generic'  { "$($inputObject.Keys | ForEach { "`r`n$padding  $($_):  $(ConvertTo-YAML -inputObject $inputObject.$_ -depth $depth -NestingLevel ($NestingLevel + 1))" })" }
                'Object'   { ("$($inputObject | Get-Member -membertype properties | Select-Object name | ForEach { "`r`n$padding $($_.name):   $(ConvertTo-YAML -inputObject $inputObject.$($_.name) -depth $NestingLevel -NestingLevel ($NestingLevel + 1))" })") }
                'XML'   { ("$($inputObject | Get-Member -membertype properties | where-object { @('xml', 'schema') -notcontains $_.name } | Select-Object name | ForEach { "`r`n$padding $($_.name):   $(ConvertTo-YAML -inputObject $inputObject.$($_.name) -depth $depth -NestingLevel ($NestingLevel + 1))" })") }
                'DataRow'   { ("$($inputObject | Get-Member -membertype properties | Select-Object name | ForEach { "`r`n$padding $($_.name):  $(ConvertTo-YAML -inputObject $inputObject.$($_.name) -depth $depth -NestingLevel ($NestingLevel + 1))" })") }
                #  'SqlDataReader'{$all = $inputObject.FieldCount; while ($inputObject.Read()) {for ($i = 0; $i -lt $all; $i++) {"`r`n$padding $($Reader.GetName($i)): $(ConvertTo-YAML -inputObject $($Reader.GetValue($i)) -depth $depth -NestingLevel ($NestingLevel+1))"}}
                default { "'$inputObject'" }
            }
        }
        catch
        {
            write-error "Error'$($_)' in script $($_.InvocationInfo.ScriptName) $($_.InvocationInfo.Line.Trim()) (line $($_.InvocationInfo.ScriptLineNumber)) char $($_.InvocationInfo.OffsetInLine) executing $($_.InvocationInfo.MyCommand) on $type object '$($inputObject)' Class: $($inputObject.GetType().Name) BaseClass: $($inputObject.GetType().BaseType.Name) "
        }
        finally { }
    }
    
    END { }
}

 
	
	<#
	    .SYNOPSIS
	        Converts from a YAMLdotNet Document to an appropriate native PowerShell object
	    
	    .DESCRIPTION
	        A typical YAML library will parse the presentation stream and compose the Representation 
        Graph. The final input process is to construct the native data structures from the YAML 
        representational graph. The advantage of this is that you can use PowerShell objects and 
        specify how your special data types are treated in the conversion process. 
        Because YAML is a superset of JSON, you still have to allow untyped values that then have to
        be checked to see what sort of data it contains.
        This routine examines each node recursively to create a data object. Each node contain
        the object, the style, tag and anchor. The mapping-style of the node is the way it is formatted
        in the document, The anchor is used where a node references another node to get its value, 
        and a tag tells you what sort of data type it needs, explicitly. This will include ‘omap’,
        ‘seq’ or ‘map’, where the node contains a list, sequence or a dictionary, or ‘float’, ‘int’,
        ‘null’, ‘bool’ or ‘str’ if it has a simple value. You can specify your own special data, such
        as coordinates, table data or whatever you wish. To cope with these, you will need to amend
        the routine
	    
	    .PARAMETER TheNode
	       This will be taken from the YAML.net document, which is one or more representational 
        models from the YAML document
	    
	    .EXAMPLE
	        		PS C:\> ConvertFrom-YAMLDocument -TheNode $value1
	
	    .EXAMPLE   
	                $result=ConvertFrom-YAMLDocument $document -verbose
	                $result|Convertto-YAML
	
	    .NOTES
	     ===========================================================================
		 Created on:   	22-Feb-16 7:57 PM
		 Created by:   	 Phil Factor
		 Organization: 	 Phil Factory
		 Filename:     	
		===========================================================================
	
	#>
<#
    .SYNOPSIS
        Converts from a YAMLdotNet Document 
    
    .DESCRIPTION
        A detailed description of the ConvertFrom-YAMLDocument function.
    
    .PARAMETER TheNode
        a node from the YAML representational model.
    
    .EXAMPLE
        		PS C:\> ConvertFrom-YAMLDocument -TheNode $value1

    .EXAMPLE   
                $result=ConvertFrom-YAMLDocument $document -verbose
                $result|Convertto-YAML

    .NOTES
     ===========================================================================
	 Created on:   	22-Feb-16 7:57 PM
	 Created by:   	 Phil Factor
	 Organization: 	 Phil Factory
	 Filename:     	
	===========================================================================

#>
function ConvertFrom-YAMLDocument
{
    [CmdletBinding()]
    param
    (
        [object]$TheNode #you pass in a node that, when you call it, will be the root node. 
    )
    #initialise variables that are needed for providing the correct powershell data type for a string-based value.
    [bool]$ABool = $false; [int]$AnInt = $null; [long]$ALong = $null; [decimal]$adecimal = $null; [single]$ASingle = $null;
    [double]$ADouble = $null; [datetime]$ADatetime = '1/1/2000';
    
    $TheTypeOfNode = $TheNode.GetType().Name # determine this
    Write-Verbose "$TheTypeOfNode = $($theNode)" #just so see what is going on
     $Style = $TheNode.Style; $Tag = $TheNode.Tag; $Anchor = $TheNode.Anchor; 
     Write-Verbose "Tag=$tag, Style=$style, Anchor=$anchor"    
    if ($TheTypeOfNode -eq 'YamlDocument') #if it is the document, then call recursively with the rrot node
    { $TheObject = ConvertFrom-YAMLDocument $TheNode.RootNode }
    elseif ($TheTypeOfNode -eq 'YamlMappingNode') #ah mapping nodes 
    {
        $TheObject = [ordered]@{ }; $theNode |
        foreach{ $TheObject.($_.Key.Value) = ConvertFrom-YAMLDocument $_.Value; }
    }
    elseif ($TheTypeOfNode -eq 'YamlScalarNode' -or $TheTypeOfNode -eq 'Object[]')
    {
        $value = "$($theNode)"
        if ($tag -eq $null)
        {
            $value = switch -Regex ($value)
            {
                # if it is one of the allowed boolean values
                '(?i)\A(?:on|yes)\z' { 'true'; break } #Deal with all the possible YAML boolenas
                '(?i)\A(?:off|no)\z' { 'false'; break }
                default { $value }
            };
        };
        
        $TheObject =
            if ($tag -ieq 'tag:yaml.org,2002:str') { [string]$Value } #it is specified as a string
            elseif ($tag -ieq 'tag:yaml.org,2002:bool') { [bool]$Value } #it is specified as a boolean
            elseif ($tag -ieq 'tag:yaml.org,2002:float') { [double]$Value } #it is specified as adouble
            elseif ($tag -ieq 'tag:yaml.org,2002:int') { [int]$Value } #it is specified as a int
            elseif ($tag -ieq 'tag:yaml.org,2002:null') { $null } #it is specified as a null
            elseif ([int]::TryParse($Value, [ref]$AnInt)) { $AnInt } #is it a short integer
            elseif ([bool]::TryParse($Value, [ref]$ABool)) { $ABool } #is it a boolean
            elseif ([long]::TryParse($Value, [ref]$ALong)) { $ALong } #is it a long integer
            elseif ([decimal]::TryParse($Value, [ref]$ADecimal)) { $ADecimal } #is it a decimal
            elseif ([single]::TryParse($Value, [ref]$ASingle)) { $ASingle } #is it a single float
            elseif ([double]::TryParse($Value, [ref]$ADouble)) { $ADouble } #is it a double float
            elseif ([datetime]::TryParse($Value, [ref]$ADatetime)) { $ADatetime } #is it a datetime
            else { [string]$Value }        
    }
    elseif ($TheTypeOfNode -eq 'Object[]') #sometimes you just get a raw object, not a node
    { $TheObject = $theNode.Value } #so you return its value
    elseif ($TheTypeOfNode -eq 'YamlSequenceNode') #in which case you 
    { $TheObject = @(); $theNode | foreach{ $TheObject += ConvertFrom-YAMLDocument $_ } }
    else { Write-Verbose "Unrecognised token $TheTypeOfNode" }
    $TheObject
}

function ConvertFrom-YAML 
    {
    param
    (
        [string]$YamlString
    )
    $stringReader = new-object System.IO.StringReader([string]$yamlString)
    $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
    $yamlStream.Load([System.IO.TextReader]$stringReader)
    ConvertFrom-YAMLDocument ($yamlStream.Documents[0])
}

Function YAMLSerialize
    {
    [CmdletBinding()]
    param
    (
         [object]$PowershellObject
    )
$Serializer = New-Object YamlDotNet.Serialization.Serializer([YamlDotNet.Serialization.SerializationOptions]::emitDefaults)
#None. Roundtrip, DisableAliases, EmitDefaults, JsonCompatible, DefaultToStaticType
$stringBuilder = New-Object System.Text.StringBuilder
$stream = New-Object System.io.StringWriter -ArgumentList $stringBuilder 
$Serializer.Serialize($stream,$PowershellObject) #System.IO.TextWriter writer, System.Object graph)
$stream.ToString()
}

Function YAMLDeserialize

    {
    [CmdletBinding()]
    param
    (
         [string]$YAMLstring
    )
$stringReader = new-object System.IO.StringReader($YAMLstring)
$Deserializer=New-Object -TypeName YamlDotNet.Serialization.Deserializer -ArgumentList $null, $null, $false
$Deserializer.Deserialize([System.IO.TextReader]$stringReader)
}


	
Export-ModuleMember ConvertTo-YAML, ConvertFrom-YAMLDocument, ConvertFrom-YAML, YAMLDeserialize, YAMLSerialize
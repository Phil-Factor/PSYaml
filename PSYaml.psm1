
<#
    .SYNOPSIS
        Get latest version of NET assembly for YAMLdotNet, Add the type
    
    .DESCRIPTION
        This basically adds the YamlDotNet assembly. If you haven't got it, it gets it gor you. If you want it to, it updates the assembly to the latest version.
    
    .PARAMETER CheckForUpdate
        Force a check for an update. This is the only reason that this function is exposed.
    
    .EXAMPLE
        		PS C:\> Initialize-PsYAML_Module -CheckForUpdate $true #check for update and load 
    
    .NOTES
        Additional information about the function.
#>
function Initialize-PsYAML_Module
{
    [CmdletBinding()]
    param
    (
        [boolean]$CheckForUpdate = $false
    )
   $YAMLDotNetLocation = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules\PSYaml"
   $NugetDistribution = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    push-location #save the current location
    Set-Location -Path $YAMLDotNetLocation #set the location in case we need an update
    if ($checkForUpdate -or !(test-path "$($YAMLDotNetLocation)\YamlDotNet\YamlDotNet*"))
    {
        #Is it missing, or are we checking for an update?
        if (-not (test-path "$($YAMLDotNetLocation)\nuget.exe")) # is nuget installed?
        {
            #No nuget! we need to install it.
            Invoke-WebRequest $NugetDistribution -OutFile "$($YAMLDotNetLocation)\nuget.exe"
        }
        Set-Alias nuget "$($YAMLDotNetLocation)\nuget.exe" -Scope Script -Verbose
        nuget install yamldotnet #now install or update YAMLDotNet
    }
    #now get the latest version of YAMLdotNet that we have
    $CurrentRelease = Get-ChildItem | where { $_.PSIsContainer } | sort CreationTime -desc | select -f 1
    pop-location
    Add-Type -Path "$YAMLDotNetLocation\$CurrentRelease\lib\dotnet\yamldotnet.dll"
    
}

Initialize-PsYAML_Module


function Install-PSYamlModule
{
    [CmdletBinding()]
    param ()
    Add-Type -assembly "system.io.compression.filesystem"
    # for the unzipping operation
    $YAMLDotNetLocation = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules\PSYaml"
    # the location of the module
    if (!(test-path "$($YAMLDotNetLocation)\YAMLdotNet")) #if the location doesn't exist
    { New-Item -ItemType Directory -Force -Path "$($YAMLDotNetLocation)\YAMLdotNet" } #create the location
    $client = new-object Net.WebClient #get a webclient to fetch the files
    $client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $client.DownloadFile('https://github.com/Phil-Factor/PSYaml/archive/master.zip', "$($YAMLDotNetLocation)PSYAML.zip")
    if ((test-path "$($YAMLDotNetLocation)\PSYaml-master")) #delete the existing version if it exists
    { Remove-Item "$($YAMLDotNetLocation)\PSYaml-master" -recurse -force }
    [io.compression.zipfile]::ExtractToDirectory("$($YAMLDotNetLocation)PSYAML.zip", $YAMLDotNetLocation)
    Copy-Item "$YAMLDotNetLocation\PSYaml-master\*.*" $YAMLDotNetLocation #copy it into place
}



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
	        Converts from a YAMLdotNet Document 
	    
	    .DESCRIPTION
	        A detailed description of the ConvertFrom-YAMLDocument function.
	    
	    .PARAMETER TheNode
	        A description of the TheNode parameter.
	    
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
        A description of the TheNode parameter.
    
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


Function JSONSerialize
    {
    [CmdletBinding()]
    param
    (
    [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [object]$PowershellObject
    )
BEGIN { }
PROCESS
    {$Serializer = New-Object YamlDotNet.Serialization.Serializer([YamlDotNet.Serialization.SerializationOptions]::JsonCompatible)
#None. Roundtrip, DisableAliases, EmitDefaults, JsonCompatible, DefaultToStaticType
$stringBuilder = New-Object System.Text.StringBuilder
$stream = New-Object System.io.StringWriter -ArgumentList $stringBuilder 
$Serializer.Serialize($stream,$PowershellObject) #System.IO.TextWriter writer, System.Object graph)
$stream.ToString()}
END {}
}

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



Function Convert-YAMLtoJSON
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

Export-ModuleMember ConvertTo-YAML, ConvertFrom-YAMLDocument, ConvertFrom-YAML, YAMLDeserialize, YAMLSerialize, JSONSerialize, Convert-YAMLtoJSON
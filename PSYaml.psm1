Function Initialize-PSYaml_Module {
    <#
        .SYNOPSIS
            Adds and update the YamlDotNet assembly.
        
        .DESCRIPTION
            Get latest version of .NET assembly for YAMLdotNet and add the type.
        
        .PARAMETER CheckForUpdate
            Force a check for an update. This is the only reason that this function is exposed.
        
        .EXAMPLE
            PS C:\> Initialize-PSYaml_Module -CheckForUpdate $True #check for update and load 
        
        .NOTES
            TODO: Additional information about the function.
    #>

    [CmdletBinding()]

    Param (
        [boolean] $CheckForUpdate = $False
    )
   
    $YAMLDotNetLocation = "$Env:Userprofile\Documents\WindowsPowerShell\Modules\PSYaml"
    $NugetDistribution = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

    # Save the current location
    Push-Location

    # Set the location in case we need an update
    Set-Location -Path $YAMLDotNetLocation\YAMLdotNet

    # Is YAMLDotNet missing or are we checking for an update?
    If ($CheckForUpdate -Or !(Test-Path "$YAMLDotNetLocation\YamlDotNet\YamlDotNet*")) {

        # Is NuGet installed?
        If (-Not (Test-Path "$YAMLDotNetLocation\NuGet.exe")) {

            # We need to install it NuGet
            Invoke-WebRequest $NugetDistribution -OutFile "$YAMLDotNetLocation\NuGet.exe"
        }

        Set-Alias nuget "$YAMLDotNetLocation\NuGet.exe" -Scope Script -Verbose

        # Now install or update YAMLDotNet
        nuget install yamldotnet -Version "4.1.0"
    }

    # Now get the latest version of YAMLdotNet that we have
    $CurrentRelease = Get-ChildItem | Where-Object { $_.PSIsContainer } | Sort-Object CreationTime -desc | Select-Object -f 1

    Pop-Location
    Add-Type -Path "$YAMLDotNetLocation\YAMLDotNet\$CurrentRelease\lib\dotnet\yamldotnet.dll"
    
}

Initialize-PSYaml_Module

Function Install-PSYamlModule {
    [CmdletBinding()]

    Param ()

    Add-Type -Assembly "System.IO.Compression.FileSystem"

    # Set location for the unzipping operation
    $YAMLDotNetLocation = "$Env:UserProfile\Documents\WindowsPowerShell\Modules\PSYaml"
    
    # If the module's location does not exist
    If (-Not (Test-Path "$YAMLDotNetLocation\YAMLdotNet")) {

        # Create the location
        New-Item -ItemType "Directory" -Force -Path "$YAMLDotNetLocation\YAMLdotNet" | Out-Null
    }

    # Create a WebClient to fetch the files
    $Client = New-Object Net.WebClient
    $Client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $Client.DownloadFile("https://github.com/Dargmuesli/PSYaml/archive/master.zip", "$YAMLDotNetLocation\PSYaml.zip")

    # Delete the existing version if it exists
    If (Test-Path "$YAMLDotNetLocation\PSYaml-master") {
        Remove-Item "$YAMLDotNetLocation\PSYaml-master" -Recurse -Force
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory("$YAMLDotNetLocation\PSYaml.zip", $YAMLDotNetLocation)
    
    # Copy it into place
    Copy-Item "$YAMLDotNetLocation\PSYaml-master\*.*" $YAMLDotNetLocation

    # Delete the downloaded files
    Remove-Item @("$YAMLDotNetLocation\PSYaml-master", "$YAMLDotNetLocation\PSYaml.zip") -Recurse -Force
}



Function ConvertTo-YAML {
    <#
        .SYNOPSIS
            Creates a YAML description of the object's data.

        .DESCRIPTION
            This produces YAML from any object you pass to it. It isn't suitable for huge objects produced by some of the cmdlets such as Get-Process, but fine for simple objects.

        .EXAMPLE
            $array=@()
            $array+=Get-Process wi* | Select-Object Handles,NPM,PM,WS,VM,CPU,Id,ProcessName 
            ConvertTo-YAML $array

        .PARAMETER Object 
             The object that contains the data.

        .PARAMETER Depth
            The depth of exploration of the object's data.

        .PARAMETER NestingLevel
            Internal use only. Required for formatting.
    #>
    
    [CmdletBinding()]

    Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True)] [AllowNull()] $InputObject,
        [Parameter(Position = 1, Mandatory = $False, ValueFromPipeline = $False)] [Int] $Depth = 16,
        [Parameter(Position = 2, Mandatory = $False, ValueFromPipeline = $False)] [Int] $NestingLevel = 0,
        [Parameter(Position = 3, Mandatory = $False, ValueFromPipeline = $False)] [Int] $XMLAsInnerXML = 0
    )
    
    Begin {}

    Process {

        # If InputObject is null, return null
        If ($InputObject -Eq $Null -And !($InputObject -Ne $Null)) {
            $P += 'null'
            Return $P
        }

        If ($NestingLevel -Eq 0) {
            '---'
        }
        
        # Create left padding for the block
        $Padding = [String] '    ' * $NestingLevel

        Try {

            # We start by getting the object's type
            $Type = $InputObject.GetType().Name

            If ($Type -Ieq 'Object[]') {

                # What it really is
                $Type = "$($InputObject.GetType().BaseType.Name)"
            }

            If ($Depth -Ilt $NestingLevel) {

                # Report the leaves in terms of object type
                $Type = 'OutOfDepth'
            } ElseIf ($Type -Ieq 'XmlDocument' -Or $Type -Ieq 'XmlElement') {

                # Convert to PS Alias
                If ($XMLAsInnerXML -Ne 0) {
                    $Type = 'InnerXML'
                } Else {
                    $Type = 'XML'
                }
            }
            
            If (@('boolean', 'byte', 'byte[]', 'char', 'datetime', 'decimal', 'double', 'float', 'single', 'guid', 'int', 'int32',
                    'int16', 'long', 'int64', 'OutOfDepth', 'RuntimeType', 'PSNoteProperty', 'regex', 'sbyte', 'string',
                    'timespan', 'uint16', 'uint32', 'uint64', 'uri', 'version', 'void', 'xml', 'datatable', 'Dictionary`2',
                    'SqlDataReader', 'datarow', 'ScriptBlock', 'type') -NotContains $Type) {
                
                # Prevent these values being identified as an object
                If ($Type -Ieq 'OrderedDictionary') {
                    $Type = 'HashTable'
                } ElseIf ($Type -Ieq 'PSCustomObject') {
                    $Type = 'PSObject'
                } ElseIf ($Type -Ieq 'List`1') {
                    $Type = 'Array'
                } ElseIf ($InputObject -Is "Array") {

                    # Whatever it thinks it is called
                    $Type = 'Array'
                } ElseIf ($InputObject -Is "HashTable") {

                    # For our purposes it is a hashtable
                    $Type = 'HashTable'
                } ElseIf (($InputObject | Get-Member -MemberType Properties | Select-Object Name | Where-Object name -Like 'Keys') -Ne $Null) {

                    # Use dot notation
                    $Type = 'generic'
                } ElseIf (($InputObject | Get-Member -MemberType Properties | Select-Object Name).Count -Gt 1) {
                    $Type = 'Object'
                }
            }

            Write-Verbose "${Padding}Type:='$Type', Object type:=$($InputObject.GetType().Name), BaseName:=$($InputObject.GetType().BaseType.Name)"
            
            Switch ($Type) {
                'ScriptBlock' {
                    "{$($InputObject.ToString())}"
                }
                'InnerXML' {
                    "|`r`n" + ($InputObject.OuterXMl.Split("`r`n") | ForEach-Object { "$Padding$_`r`n" })
                }
                'DateTime' {

                    # s=SortableDateTimePattern (based on ISO 8601) using local time
                    $InputObject.ToString('s')
                }
                'Byte[]' {
                    $String = [System.Convert]::ToBase64String($InputObject)

                    If ($String.Length -Gt 100) {

                        # Format it to YAML spec. Signal that we are going to use the readable Base64 string format
                        '!!binary "\' + "`r`n"

                        #$Bits = @(); $Length = $String.Length; $IndexIntoString = 0; $Wrap = 100
                        While ($Length -Gt $IndexIntoString + $Wrap) {
                            $Padding + $String.Substring($IndexIntoString, $Wrap).Trim() + "`r`n"
                            $IndexIntoString += $Wrap
                        }

                        If ($IndexIntoString -Lt $Length) {
                            $Padding + $String.Substring($IndexIntoString).Trim() + "`r`n"
                        } Else {
                            "`r`n"
                        }
                    }
                    
                    Else {
                        '!!binary "' + $($String -replace '''', '''''') + '"'
                    }
                }
                'Boolean' {
                    "$(&{
                        If ($InputObject -Eq $True) {
                            'true'
                        } Else {
                            'false'
                        }
                    })"
                }
                'string' {
                    $String = "$InputObject"

                    If ($String -Match '[\r\n]' -Or $String.Length -Gt 80) {

                        # Format it to YAML spec. Signal that we are going to use the readable 'newlines-folded' format.
                        $Folded = ">`r`n"
                        $String.Split("`n") | ForEach-Object {
                            $Length = $_.Length; $IndexIntoString = 0; $Wrap = 80

                            While ($Length -Gt $IndexIntoString + $Wrap) {
                                $Breakpoint = $Wrap
                                $Earliest = $_.Substring($IndexIntoString, $Wrap).LastIndexOf(' ')
                                $Latest = $_.Substring($IndexIntoString + $Wrap).IndexOf(' ')

                                If (($Earliest -Eq -1) -Or ($Latest -Eq -1)) {
                                    $Breakpoint = $Wrap
                                } ElseIf ($Wrap - $Earliest -Lt ($Latest)) {
                                    $BreakPoint = $Earliest
                                } Else {
                                    $BreakPoint = $Wrap + $Latest
                                }

                                If (($Wrap - $Earliest) + $Latest -Gt 30) {

                                    # In case it is a string without spaces
                                    $BreakPoint = $Wrap
                                }

                                $Folded += $Padding + $_.Substring($IndexIntoString, $BreakPoint).Trim() + "`r`n"
                                $IndexIntoString += $BreakPoint
                            }

                            If ($IndexIntoString -Lt $Length) {
                                $Folded += $Padding + $_.Substring($IndexIntoString).Trim() + "`r`n`r`n"
                            } Else {
                                $Folded += "`r`n`r`n"
                            }
                        }

                        $Folded
                    } Else {
                        "'$($String -replace '''', '''''')'"
                    }
                }
                'Char' {
                    "([Int] $InputObject)"
                }
                {@('byte', 'decimal', 'double', 'float', 'single', 'int', 'int32', 'int16', `
                            'long', 'int64', 'sbyte', 'uint16', 'uint32', 'uint64') -Contains $_ } {
                    
                    # Rendered as is without single quotes
                    "$InputObject"
                }
                'PSNoteProperty' {
                    "$(ConvertTo-YAML -InputObject $InputObject.Value -Depth $Depth -NestingLevel ($NestingLevel + 1))"
                }
                'Array' {
                    "$($InputObject | ForEach-Object {
                        "`r`n$Padding- $(ConvertTo-YAML -InputObject $_ -Depth $Depth -NestingLevel ($NestingLevel + 1))"
                    })"
                }
                'HashTable' {
                    ("$($InputObject.GetEnumerator() | ForEach-Object {
                        "`r`n$Padding $($_.Name): " + (ConvertTo-YAML -InputObject $_.Value -Depth $Depth -NestingLevel ($NestingLevel + 1))
                    })")
                }
                'Dictionary`2' {
                    ("$($InputObject.GetEnumerator() | ForEach-Object {
                        "`r`n$Padding $($_.Key): " + (ConvertTo-YAML -InputObject $_.Value -Depth $Depth -NestingLevel ($NestingLevel + 1))
                    })")
                }
                'PSObject' {
                    ("$($InputObject.PSObject.Properties | ForEach-Object {
                        "`r`n$Padding $($_.Name): " + (ConvertTo-YAML -InputObject $_ -Depth $Depth -NestingLevel ($NestingLevel + 1))
                    })")
                }
                'generic' {
                    "$($InputObject.Keys | ForEach-Object {
                        "`r`n$Padding $($_): $(ConvertTo-YAML -InputObject $InputObject.$_ -Depth $Depth -NestingLevel ($NestingLevel + 1))"
                    })"
                }
                'Object' {
                    ("$($InputObject | Get-Member -MemberType Properties | Select-Object Name | ForEach-Object {
                        "`r`n$Padding $($_.name): $(ConvertTo-YAML -InputObject $InputObject.$($_.name) -Depth $NestingLevel -NestingLevel ($NestingLevel + 1))"
                    })")
                }
                'XML' {
                    ("$($InputObject | Get-Member -MemberType Properties | Where-Object {
                        @('xml', 'schema') -notcontains $_.name
                    } | Select-Object Name | ForEach-Object {
                        "`r`n$Padding $($_.name): $(ConvertTo-YAML -InputObject $InputObject.$($_.name) -Depth $Depth -NestingLevel ($NestingLevel + 1))"
                    })")
                }
                'DataRow' {
                    ("$($InputObject | Get-Member -MemberType Properties | Select-Object Name | ForEach-Object {
                        "`r`n$Padding $($_.name): $(ConvertTo-YAML -InputObject $InputObject.$($_.name) -Depth $Depth -NestingLevel ($NestingLevel + 1))"
                    })")
                }

                # 'SqlDataReader'{$all = $InputObject.FieldCount; While ($InputObject.Read()) {for ($i = 0; $i -Lt $all; $i++) {"`r`n$Padding $($Reader.GetName($i)): $(ConvertTo-YAML -InputObject $($Reader.GetValue($i)) -Depth $Depth -NestingLevel ($NestingLevel+1))"}}
                Default {
                    "'$InputObject'"
                }
            }
        } Catch {
            Write-Error "Error'$($_)' in script $($_.InvocationInfo.ScriptName) $($_.InvocationInfo.Line.Trim()) (line $($_.InvocationInfo.ScriptLineNumber)) char $($_.InvocationInfo.OffsetInLine) executing $($_.InvocationInfo.MyCommand) on $Type object '$($InputObject)' Class: $($InputObject.GetType().Name) BaseClass: $($InputObject.GetType().BaseType.Name)"
        }
    }
    
    END {}
}

FunctionConvertFrom-YAMLDocument {
    <#
        .SYNOPSIS
            Converts from a YAMLdotNet Document 
        
        .DESCRIPTION
            A detailed description of the ConvertFrom-YAMLDocument function.
        
        .PARAMETER TheNode
            A description of the TheNode parameter.
        
        .EXAMPLE
            PS C:\> ConvertFrom-YAMLDocument -TheNode $Value1

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

    [CmdletBinding()]

    Param (

        # You pass in a node that, when you call it, will be the root node. 
        [Object] $TheNode
    )

    # Initialise variables that are needed for providing the correct powershell data type for a string-based value.
    [Bool] $ABool = $False
    [Int] $AnInt = $Null
    [Long] $ALong = $Null
    [Decimal] $ADecimal = $Null
    [Single] $ASingle = $Null
    [Double] $ADouble = $Null
    [DateTime] $ADatetime = '1/1/2000';
    
    # Determine this
    $TheTypeOfNode = $TheNode.GetType().Name

    # Just so see what is going on
    Write-Verbose "$TheTypeOfNode = $($TheNode)"

    $Style = $TheNode.Style
    $Tag = $TheNode.Tag
    $Anchor = $TheNode.Anchor

    Write-Verbose "Tag=$Tag, Style=$style, Anchor=$anchor"    
    
    # If it is the document, then call recursively with the rrot node
    If ($TheTypeOfNode -Eq 'YamlDocument') {
        $TheObject = ConvertFrom-YAMLDocument $TheNode.RootNode
    } ElseIf ($TheTypeOfNode -Eq 'YamlMappingNode') {

        # Ah mapping nodes 
        $TheObject = [ordered]@{ }; $TheNode | ForEach-Object {
            $TheObject.($_.Key.Value) = ConvertFrom-YAMLDocument $_.Value
        }
    } ElseIf ($TheTypeOfNode -Eq 'YamlScalarNode' -Or $TheTypeOfNode -Eq 'Object[]') {
        $Value = "$TheNode"

        If ($Tag -Eq $Null) {
            $Value = Switch -Regex ($Value) {

                # If it is one of the allowed boolean values
                '(?i)\A(?:on|yes)\z' {
                    'true'
                    break
                }

                #Deal with all the possible YAML boolenas
                '(?i)\A(?:off|no)\z' {
                    'false'
                    break
                }
                Default {
                    $Value
                }
            }
        }
        
        $TheObject = If ($Tag -Ieq 'tag:yaml.org,2002:str') {

            # It is specified as a string
            [String] $Value
        } ElseIf ($Tag -Ieq 'tag:yaml.org,2002:bool') {
                
            # It is specified as a boolean
            [Bool] $Value
        } ElseIf ($Tag -Ieq 'tag:yaml.org,2002:float') {
                
            # It is specified as a double
            [Double] $Value
        } ElseIf ($Tag -Ieq 'tag:yaml.org,2002:int') {
                
            # It is specified as a int
            [Int] $Value
        } ElseIf ($Tag -Ieq 'tag:yaml.org,2002:null') {
                
            # It is specified as a null
            $Null
        } ElseIf ($Tag -Ieq 'tag:yaml.org,2002:timestamp') {
                
            # It is date/timestamp
            [DateTime] $Value
        } ElseIf ($Tag -Ieq 'tag:yaml.org,2002:binary') {
            [System.Convert]::FromBase64String($Value)
        } ElseIf ([Int]::TryParse($Value, [ref] $AnInt)) {
                
            # Is it a short integer
            $AnInt
        } ElseIf ([Bool]::TryParse($Value, [ref] $ABool)) {
                
            # Is it a boolean
            $ABool
        } ElseIf ([Long]::TryParse($Value, [ref] $ALong)) {
                
            # Is it a long integer
            $ALong
        } ElseIf ([Decimal]::TryParse($Value, [ref] $ADecimal)) {
                
            # Is it a decimal
            $ADecimal
        } ElseIf ([Single]::TryParse($Value, [ref] $ASingle)) {
                
            # Is it a single float
            $ASingle
        } ElseIf ([Double]::TryParse($Value, [ref] $ADouble)) {
                
            # Is it a double float
            $ADouble
        } ElseIf ([DateTime]::TryParse($Value, [ref] $ADatetime)) {

            # Is it a datetime
            $ADatetime
        } Else {
            [String] $Value
        }

        # Sometimes you just get a raw object, not a node
    } ElseIf ($TheTypeOfNode -Eq 'Object[]') {

        # So you return its value
        $TheObject = $TheNode.Value
    } ElseIf ($TheTypeOfNode -Eq 'YamlSequenceNode') {
        
        # In which case you 
        $TheObject = @()
        $TheNode | ForEach-Object {
            $TheObject += ConvertFrom-YAMLDocument $_
        }
    } Else {
        Write-Verbose "Unrecognised token $TheTypeOfNode"
    }
    
    $TheObject
}

Function ConvertFrom-YAML {
    [CmdletBinding()]

    Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True)] $YamlString
    )
    
    BEGIN {}

    PROCESS {
        $StringReader = New-Object System.IO.StringReader([String] $YamlString)
        $YamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
        $YamlStream.Load([System.IO.TextReader] $StringReader)

        ConvertFrom-YAMLDocument ($YamlStream.Documents[0])
    }

    END {}
}


Function Export-JSON {
    [CmdletBinding()]

    Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True)] [Object] $PowershellObject
    )
    
    BEGIN {}

    PROCESS {
        $Serializer = New-Object YamlDotNet.Serialization.Serializer([YamlDotNet.Serialization.SerializationOptions]::JsonCompatible)
        
        #None. Roundtrip, DisableAliases, EmitDefaults, JsonCompatible, DefaultToStaticType
        $StringBuilder = New-Object System.Text.StringBuilder
        $Stream = New-Object System.IO.StringWriter -ArgumentList $StringBuilder 
        $Serializer.Serialize($Stream, $PowershellObject) #System.IO.TextWriter writer, System.Object graph)
        $Stream.ToString()
    }

    END {}
}

Function Export-YAML {
    [CmdletBinding()]

    Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True)] [Object] $PowershellObject
    )

    BEGIN {}

    PROCESS {
        $Serializer = New-Object YamlDotNet.Serialization.Serializer([YamlDotNet.Serialization.SerializationOptions]::emitDefaults)
        
        #None. Roundtrip, DisableAliases, EmitDefaults, JsonCompatible, DefaultToStaticType
        $StringBuilder = New-Object System.Text.StringBuilder
        $Stream = New-Object System.IO.StringWriter -ArgumentList $StringBuilder 
        $Serializer.Serialize($Stream, $PowershellObject) #System.IO.TextWriter writer, System.Object graph)
        $Stream.ToString()
    }

    END {}
}

Function Import-YAML {
    [CmdletBinding()]

    Param (
        $YamlString
    )

    $StringReader = New-Object System.IO.StringReader([String] $YamlString)
    $Deserializer = New-Object -TypeName YamlDotNet.Serialization.Deserializer -ArgumentList $Null, $Null, $False
    $Deserializer.Deserialize([System.IO.TextReader] $StringReader)
}



Function Convert-YAMLtoJSON {
    Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True)]
        $YamlString
    )

    BEGIN {}

    PROCESS {
        $StringReader = New-Object System.IO.StringReader([String] $YamlString)
        $Deserializer = New-Object -TypeName YamlDotNet.Serialization.Deserializer -ArgumentList $Null, $Null, $False
        $NetObject = $Deserializer.Deserialize([System.IO.TextReader] $StringReader)
        $Serializer = New-Object YamlDotNet.Serialization.Serializer([YamlDotNet.Serialization.SerializationOptions]::JsonCompatible)
        
        #None. Roundtrip, DisableAliases, EmitDefaults, JsonCompatible, DefaultToStaticType
        $StringBuilder = New-Object System.Text.StringBuilder
        $Stream = New-Object System.IO.StringWriter -ArgumentList $StringBuilder
        $Serializer.Serialize($Stream, $NetObject)
        $Stream.ToString()
    }

    END {}
}

Export-ModuleMember ConvertTo-YAML, ConvertFrom-YAMLDocument, ConvertFrom-YAML, Import-YAML, Export-YAML, Export-JSON, Convert-YAMLtoJSON

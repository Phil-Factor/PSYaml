function ConvertTo-Yaml
{
<#
 .SYNOPSIS
   creates a YAML description of the data in the object
 .DESCRIPTION
   This produces YAML from any object you pass to it. It isn't suitable for the huge objects produced by some of the cmdlets such as Get-Process, but fine for simple objects
 .EXAMPLE
   $array=@()
   $array+=Get-Process wi* |  Select-Object-Object Handles,NPM,PM,WS,VM,CPU,Id,ProcessName 
   ConvertTo-YAML $array

 .PARAMETER Object 
   the object that you want scripted out
 .PARAMETER Depth
   The depth that you want your object scripted to
 .PARAMETER Nesting Level
   internal use only. required for formatting
#>
    [OutputType('System.String')]
    
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
        # if it is null return null
        If ( !($inputObject) )
        {
            $p += 'null'
            return $p
        } 

        if ($NestingLevel -eq 0) { '---' }
        
        $padding = [string]'  ' * $NestingLevel # lets just create our left-padding for the block
        try
        {
            $Type = $inputObject.GetType().Name # we start by getting the object's type
            if ($Type -ieq 'Object[]')
            { 
                #what it really is
                $Type = "$($inputObject.GetType().BaseType.Name)" 
            }

            #report the leaves in terms of object type
            if ($depth -ilt $NestingLevel)
            {
                $Type = 'OutOfDepth' 
            } 
            elseif ($Type -ieq 'XmlDocument' -or $Type -ieq 'XmlElement')
            {
                if ($XMLAsInnerXML -ne 0)
                {
                    $Type = 'InnerXML' 
                }
                else
                { 
                    $Type = 'XML'
                }
            } # convert to PS Alias

            # prevent these values being identified as an object
            if (@('boolean', 'byte', 'byte[]', 'char', 'datetime', 'decimal', 'double', 'float', 'single', 'guid', 'int', 'int32',
                    'int16', 'long', 'int64', 'OutOfDepth', 'RuntimeType', 'PSNoteProperty', 'regex', 'sbyte', 'string',
                    'timespan', 'uint16', 'uint32', 'uint64', 'uri', 'version', 'void', 'xml', 'datatable', 'Dictionary`2',
                    'SqlDataReader', 'datarow', 'ScriptBlock', 'type') -notcontains $type)
            {
                if ($Type -ieq 'OrderedDictionary')
                {
                    $Type = 'HashTable' 
                }
                elseif ($Type -ieq 'PSCustomObject')
                {
                    $Type = 'PSObject'
                }
                elseif ($Type -ieq 'List`1')
                {
                    $Type = 'Array'
                }
                elseif ($inputObject -is "Array")
                {
                    $Type = 'Array'
                } # whatever it thinks it is called
                elseif ($inputObject -is "HashTable")
                {
                    $Type = 'HashTable'
                } # for our purposes it is a hashtable
                elseif (!($inputObject | Get-Member -membertype Properties | Select-Object name | Where-Object name -like 'Keys'))
                {
                    $Type = 'generic'
                } #use dot notation
                elseif (($inputObject | Get-Member -membertype Properties | Select-Object name).count -gt 1)
                {
                    $Type = 'Object'
                }
            }
            write-verbose "$($padding)Type:='$Type', Object type:=$($inputObject.GetType().Name), BaseName:=$($inputObject.GetType().BaseType.Name) "
            
            switch ($Type)
            {
                'ScriptBlock'{ "{$($inputObject.ToString())}" }
                'InnerXML'        { "|`r`n" + ($inputObject.OuterXMl.Split("`r`n") | ForEach-Object{ "$padding$_`r`n" }) }
                'DateTime'   { $inputObject.ToString('s') } # s=SortableDateTimePattern (based on ISO 8601) using local time
                'Byte[]'     {
                    $string = [System.Convert]::ToBase64String($inputObject)
                    if ($string.Length -gt 100)
                    {
                        # right, we have to format it to YAML spec.
                        '!!binary "\' + "`r`n" # signal that we are going to use the readable Base64 string format
                        #$bits = @()
                        $length = $string.Length
                        $IndexIntoString = 0
                        $wrap = 100
                        while ($length -gt $IndexIntoString + $Wrap)
                        {
                            $padding + $string.Substring($IndexIntoString, $wrap).Trim() + "`r`n"
                            $IndexIntoString += $wrap
                        }
                        if ($IndexIntoString -lt $length)
                        {
                            $padding + $string.Substring($IndexIntoString).Trim() + "`r`n"
                        }
                        else
                        {
                            "`r`n" 
                        }
                    }
                    
                    else
                    {
                        '!!binary "' + $($string -replace '''', '''''') + '"'
                    }
                    
                }
                'Boolean' {
                    "$(&{
                            if ($inputObject -eq $true) { 'true' }
                            else { 'false' }
                        })"
                }
                'string' {
                    $String = "$inputObject"
                    if ($string -match '[\r\n]' -or $string.Length -gt 80)
                    {
                        # right, we have to format it to YAML spec.
                        $folded = ">`r`n" # signal that we are going to use the readable 'newlines-folded' format
                        $string.Split("`n") | ForEach-Object {
                            $length = $_.Length
                            $IndexIntoString = 0
                            $wrap = 80
                            while ($length -gt $IndexIntoString + $Wrap)
                            {
                                $BreakPoint = $wrap
                                $earliest = $_.Substring($IndexIntoString, $wrap).LastIndexOf(' ')
                                $latest = $_.Substring($IndexIntoString + $wrap).IndexOf(' ')
                                if (($earliest -eq -1) -or ($latest -eq -1))
                                {
                                    $BreakPoint = $wrap
                                }
                                elseif ($wrap - $earliest -lt ($latest))
                                {
                                    $BreakPoint = $earliest
                                }
                                else
                                {
                                    $BreakPoint = $wrap + $latest
                                }
                                
                                if (($wrap - $earliest) + $latest -gt 30)
                                {
                                    $BreakPoint = $wrap # in case it is a string without spaces
                                } 
                                
                                $folded += $padding + $_.Substring($IndexIntoString, $BreakPoint).Trim() + "`r`n"
                                $IndexIntoString += $BreakPoint
                            }

                            if ($IndexIntoString -lt $length)
                            {
                                $folded += $padding + $_.Substring($IndexIntoString).Trim() + "`r`n`r`n"
                            }
                            else
                            {
                                $folded += "`r`n`r`n"
                            }
                        }
                        $folded
                    }
                    else
                    {
                        "'$($string -replace '''', '''''')'"
                    }
                }
                'Char'     { "([int]$inputObject)" }
                {
                    @('byte', 'decimal', 'double', 'float', 'single', 'int', 'int32', 'int16', `
                        'long', 'int64', 'sbyte', 'uint16', 'uint32', 'uint64') -contains $_
                }
                { "$inputObject" } # rendered as is without single quotes
                'PSNoteProperty' { "$(ConvertTo-YAML -inputObject $inputObject.Value -depth $depth -NestingLevel ($NestingLevel + 1))" }
                'Array'    { "$($inputObject | Foreach-Object { "`r`n$padding- $(ConvertTo-YAML -inputObject $_ -depth $depth -NestingLevel ($NestingLevel + 1))" })" }
                'HashTable'{
                    ("$($inputObject.GetEnumerator() | Foreach-Object {
                                "`r`n$padding  $($_.Name): " +
                                (ConvertTo-YAML -inputObject $_.Value -depth $depth -NestingLevel ($NestingLevel + 1))
                            })")
                }
                'Dictionary`2'{
                    ("$($inputObject.GetEnumerator() | Foreach-Object {
                                "`r`n$padding  $($_.Key): " +
                                (ConvertTo-YAML -inputObject $_.Value -depth $depth -NestingLevel ($NestingLevel + 1))
                            })")
                }
                'PSObject' { ("$($inputObject.PSObject.Properties | Foreach-Object { "`r`n$padding $($_.Name): " + (ConvertTo-YAML -inputObject $_ -depth $depth -NestingLevel ($NestingLevel + 1)) })") }
                'generic'  { "$($inputObject.Keys | Foreach-Object { "`r`n$padding  $($_):  $(ConvertTo-YAML -inputObject $inputObject.$_ -depth $depth -NestingLevel ($NestingLevel + 1))" })" }
                'Object'   { ("$($inputObject | Get-Member -membertype properties | Select-Object-Object name | Foreach-Object { "`r`n$padding $($_.name):   $(ConvertTo-YAML -inputObject $inputObject.$($_.name) -depth $NestingLevel -NestingLevel ($NestingLevel + 1))" })") }
                'XML'   { ("$($inputObject | Get-Member -membertype properties | Where-Object-object { @('xml', 'schema') -notcontains $_.name } | Select-Object-Object name | Foreach-Object { "`r`n$padding $($_.name):   $(ConvertTo-YAML -inputObject $inputObject.$($_.name) -depth $depth -NestingLevel ($NestingLevel + 1))" })") }
                'DataRow'   { ("$($inputObject | Get-Member -membertype properties | Select-Object-Object name | Foreach-Object { "`r`n$padding $($_.name):  $(ConvertTo-YAML -inputObject $inputObject.$($_.name) -depth $depth -NestingLevel ($NestingLevel + 1))" })") }
                <# 
                'SqlDataReader'{ $all = $inputObject.FieldCount
                    while ($inputObject.Read()) {for ($i = 0; $i -lt $all; $i++)
                    {"`r`n$padding $($Reader.GetName($i)): $(ConvertTo-YAML -inputObject $($Reader.GetValue($i)) -depth $depth -NestingLevel ($NestingLevel+1))"}}
                #>
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
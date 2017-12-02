function ConvertFrom-YAMLDocument
{
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
        Created on:    22-Feb-16 7:57 PM
        Created by:     Phil Factor
        Organization:   Phil Factory
        Filename:      
    ===========================================================================

#>
    [CmdletBinding()]
    param (
            [object]$TheNode #you pass in a node that, when you call it, will be the root node. 
          )

    #initialise variables that are needed for providing the correct powershell data type for a string-based value.
    [bool]$ABool       = $false
    [int]$AnInt        = $null
    [long]$ALong       = $null
    [decimal]$adecimal = $null
    [single]$ASingle   = $null
    [double]$ADouble   = $null
    [datetime]$ADatetime = '1/1/2000'

    $TheTypeOfNode = $TheNode.GetType().Name # determine this
    
    Write-Verbose "$TheTypeOfNode = $($theNode)" #just so see what is going on
    $Style = $TheNode.Style
    $Tag = $TheNode.Tag
    $Anchor = $TheNode.Anchor

    Write-Verbose "Tag=$tag, Style=$style, Anchor=$anchor"    
    
    #if it is the document, then call recursively with the rrot node
    if ($TheTypeOfNode -eq 'YamlDocument') 
    { 
        $TheObject = ConvertFrom-YAMLDocument $TheNode.RootNode 
    }
    elseif ($TheTypeOfNode -eq 'YamlMappingNode') #ah mapping nodes 
    {
        $TheObject = [ordered]@{ }
        $theNode | ForEach-Object{ 
                        $TheObject.($_.Key.Value) = ConvertFrom-YAMLDocument $_.Value
                   }
    }
    elseif ($TheTypeOfNode -eq 'YamlScalarNode' -or $TheTypeOfNode -eq 'Object[]')
    {
        $value = "$($theNode)"
        if (! $tag)
        {
            $value = switch -Regex ($value)
            {
                # if it is one of the allowed boolean values
                '(?i)\A(?:on|yes)\z' { 'true'
                                        break
                                     } #Deal with all the possible YAML boolenas
                '(?i)\A(?:off|no)\z' { 'false'
                                       break
                                     }
                default { $value }
            }

        }


        $TheObject = if ($tag -ieq 'tag:yaml.org,2002:str') { [string]$Value } #it is specified as a string
                     elseif ($tag -ieq 'tag:yaml.org,2002:bool') { [bool]$Value } #it is specified as a boolean
                     elseif ($tag -ieq 'tag:yaml.org,2002:float') { [double]$Value } #it is specified as adouble
                     elseif ($tag -ieq 'tag:yaml.org,2002:int') { [int]$Value } #it is specified as a int
                     elseif ($tag -ieq 'tag:yaml.org,2002:null') { $null } #it is specified as a null
                     elseif ($tag -ieq 'tag:yaml.org,2002:timestamp') {[datetime]$Value} #it is date/timestamp
                     elseif ($tag -ieq 'tag:yaml.org,2002:binary') {[System.Convert]::FromBase64String($Value)}
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
    { 
        $TheObject = $theNode.Value #so you return its value
    } 
    elseif ($TheTypeOfNode -eq 'YamlSequenceNode') #in which case you 
    { 
        $TheObject = @()
        $theNode | ForEach-Object{ 
                                    $TheObject += ConvertFrom-YAMLDocument $_ 
                                 }
        return ,$TheObject
    }
    else
    {
        Write-Verbose "Unrecognised token $TheTypeOfNode" 
    }
    
    Return $TheObject
}

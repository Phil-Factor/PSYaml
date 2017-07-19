## PSYaml

PSYaml is a simple PowerShell module that allows you to serialize PowerShell objects to "Yet Another Markup Language" (YAML) documents and deserialize YAML documents to PowerShell objects. It uses [Antoine Aubry's](http://aaubry.net) [excellent YamlDotNet library](http://aaubry.net/pages/yamldotnet.html).

Prior versions of this module required that you manually procure and move the .NET library into a folder before the module would function. For reference, please reference the [legacy documentation](.\Documentation.adoc).

## Usage

```powershell
import-module psyaml 
```
Once the module is in place and working, you can execute code like this 
```powershell
[ordered]@{
    Computername = $(Get-wmiobject win32_operatingsystem).csname
    OS = $(Get-wmiobject win32_operatingsystem).caption
    'Uptime (hours)' = ((get-date) - ([wmiclass]"").ConvertToDateTime((Get-wmiobject win32_operatingsystem).LastBootUpTime)).Hours
    Make = $(get-wmiobject win32_computersystem).model
    Manufacturer = $(get-wmiobject win32_computersystem).manufacturer
    'Memory (Gb)' = $(Get-WmiObject win32_computersystem).TotalPhysicalMemory/1GB -as [int]
    Processes = (Get-Process).Count
    drives =  Get-WmiObject Win32_logicaldisk|select DeviceID, description
 } | ConvertTo-YAML 
```
to give you a YAML representation of the data that is easy to assimilate.
 
```yaml
---
  Computername: 'LTPFACTOR' 
  OS: 'Microsoft Windows 8.1 Enterprise' 
  Uptime (hours): 21 
  Make: 'Latitude E8770' 
  Manufacturer: 'Dell Inc.' 
  Memory (Gb): 8 
  Processes: 169 
  Drives: 
  - 
     DeviceID: 'C:' 
     description: 'Local Fixed Disk' 
  - 
     DeviceID: 'K:' 
     description: 'Network Connection' 
  - 
     DeviceID: 'L:' 
     description: 'Network Connection' 
  - 
     DeviceID: 'M:' 
     description: 'Network Connection' 
  - 
     DeviceID: 'N:' 
     description: 'Network Connection' 
  - 
     DeviceID: 'P:' 
     description: 'Network Connection' 
  - 
     DeviceID: 'S:' 
     description: 'Network Connection'
```

Try it with something like `Format-table` and you'll probably agree that there is a place for rendering hierarchical information in a human-oriented way. 

## YAML and PowerShell

When you need to use structured data in PowerShell, you have to think of writing it out - serializing it – and reading it into an object– deserialising it. You’ll hear talk of serializing objects, but really, you’re only serializing the data within it, such as properties, lists, collections, dictionaries and so on, rather than the methods. In a compiled language, a serialized object can’t do anything for itself once it has been deserialised and re-serialised. It is just a container for data. PowerShell is unusual in that it can include scripts in objects, as ScriptMethods and ScriptProperties, so it is theoretically possible to transfer both between PowerShell applications, but this is out of the scope of this article.

You’ve got some choice in PowerShell of how you serialize objects into structured documents, and back again. The two built-in formats are XML and JSON. I’ll be showing you how to get to use a third: YAML.

## Why YAML?

You’d need a good reason for not using XML. It is the obvious format for juggling with data. PowerShell allows you to query it and treat it as an object. If you use XML Schemas, you have a very robust system.
The downside of XML is that it is complex, arcane, and the XML documents can’t be easily read or altered by humans. It can take a long time to process.

JSON is popular because it is so simple that any language can be used to read or write it. The downside is that it doesn’t do much, and has a restricted range of datatypes. You can’t actually specify the data type of a value, for example. It isn’t an intuitive way of laying data out on the page.
YAML is a formalization of the way that we used to lay out taxonomies and forms of structured data before computers. It is easy to understand. When you start doing bulleted lists within lists, it starts to look like YAML. As far as readability goes, here is YAML document

```yaml
---
phil:
  name: Phil Factor
  job: Developer
  skills:
   - SQL  
   - python
   - perl
   - pascal
- derek:
  name: Derek DBA
  job: DBA
  skills:
   - TSQL
   - fortran
   - cobol 
```


And here is the same in JSON.

```json
[ { phil: 
   { name: 'Phil Factor',
    job: 'Developer',
    skills: [ 'SQL', 'python', 'perl', 'pascal' ] } },
 { derek: 
   { name: 'Derek DBA',
    job: 'DBA',
    skills: [ 'TSQL', 'fortran', 'cobol' ] } } ]
```

YAML is officially now a superset of JSON, and so a YAML serializer can usually be persuaded to use the JSON ‘brackety’ style if you prefer, or require, that. The PSYaml module has a function just to convert from the indented dialect of YAML to the 'Brackety' dialect aka JSON. Beware that not everything in YAML will convert to JSON so it is possible to get errors in consequence. 

```powershell
import-module psyaml
Convert-YAMLtoJSON @"
# Employee records
-  phil:
    name: Phil Factor
    job: Developer
    skills:
      - SQL   
      - python
      - perl
      - pascal
-  derek:
    name: Derek DBA
    job: DBA
    skills:
      - TSQL
      - fortran
      - cobol
"@
```
which will give ...

```json

[{"phil": {"name": "Phil Factor", "job": "Developer", "skills": ["SQL", "python", "perl", "pascal"]}}, {"derek": {"name": "Derek DBA", "job": "DBA", "skills": ["TSQL", "fortran", "cobol"]}}]

```

YAML also allows you to specify the data type of its values explicitly. If you wish to ensure that a datatype is read correctly, and Mr and Mrs Null will agree with me on this, you can precede the value with `!!float`, `!!int`, `!!null`, `!!timestamp`, `!!bool`, `!!binary`, `!!Yaml` or `!!str`. These are the most common YAML datatypes that you are likely to across, and any deserializer must cope with them. YAML also allows you to specify a data type that is specific to a particular language or framework, such as geographic coordinates. YAML also contains references, which refer to an existing element in the same document. So, if an element is repeated later in a YAML document, you can simply refer to the element using a short-hand name.

Another advantage to YAML is that you can specify the type of set or sequence, and whether it is ordered or unordered. It is much more attuned to the rich variety of data that is around.

I use YAML a great deal for documentation and for configuration settings. I started off by using PowerYAML which is a thin layer around YamlDotNet. Unfortunately, although YamlDotNet is excellent, PowerYAML hadn’t implemented any serialiser, hadn’t implemented data type tags, and couldn’t even auto-detect the data type. As it wasn’t being actively maintained, and was incompatible with the current version of the YamlDotNet library that was doing all the heavy work, I wrote my own module using YamlDotNet directly.

You merely load the module:
```powershell
import-module psyaml 
```

and you will have a number of functions that you require.

We bundle the YamlDotNet library with the module to streamline module usage.

And we can then create some simple functions

```powershell
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

```
This will give us the basics. Naturally, there is a lot more we can, and will, do; but this will get you started. Of course, this is all done for you in PSYaml and you can access these very functions. 

Now we just want a simple YAML string to test out the plumbing.
```powershell
    $YamlString =@"
    invoice: !!int 34843
    date   : 2001-01-23
    approved: yes
    bill-to: &id001
        given  : Chris
        family : Dumars
        address:
            lines: |
                458 Walkman Dr.
                Suite #292
            city    : Royal Oak
            state   : MI
            postal  : 48046
    ship-to: *id001
    product:
        - sku         : BL394D
          quantity    : 4
          description : Basketball
          price       : 450.00
        - sku         : BL4438H
          quantity    : 1
          description : Super Hoop
          price       : 2392.00
    tax  : 251.42
    total: 4443.52
    comments: >
        Late afternoon is best.
        Backup contact is Nancy
        Billsmer @ 338-4338.

"@ 
```

So let’s create a PowerShell object, and convince ourselves that it can read it in correctly by taking the object it produced, accessing properties from it and then outputting it as JSON.

```powershell
YAMLSerialize (YAMLDeserialize $yamlString) 
```

You should get the simple invoice back again. Job done? Well, possibly, but if you need to process the results in PowerShell, you may still hit problems. 
You’d expect, from using ConvertFrom-JSON, that this would work:

```powershell
$MyInvoice=YAMLDeserialize $yamlString
$BillTo=$MyInvoice.'bill-to' 

"Dispatch this to $($BillTo.given) $($BillTo.family) at the address: 
 $($BillTo.address.lines)$($BillTo.address.city)
$($BillTo.address.state)
($($BillTo.address.postal))" 
```

But it doesn’t. What is also bad is that in the PowerShell IDE, you haven’t got the intellisense prompt for the object either. You want the equivalent of this to happen with YAML

```powershell
$JSONInvoice=convertFrom-JSON @'
{
  "invoice": 34843,
  "date": "\/Date(980208000000)\/",
  "approved": true,
  "bill-to": {
          "given": "Chris",
          "family": "Dumars",
          "address": {
                  "lines": "458 Walkman Dr.\nSuite #292\n",
                  "city": "Royal Oak",
                  "state": "MI",
                  "postal": 48046
                }
        },
  "ship-to": "id001",
  "product": [
          {
            "sku": "BL394D",
            "quantity": 4,
            "description": "Basketball",
            "price": 450.00
          },
          {
            "sku": "BL4438H",
            "quantity": 1,
            "description": "Super Hoop",
            "price": 2392.00
          }
        ],
  "tax": 251.42,
  "total": 4443.52,
  "comments": "Late afternoon is best. Backup contact is Nancy Billsmer @ 338-4338.\n"
}
'@
$BillTo=$jsonInvoice.'bill-to'

"Dispatch this to $($BillTo.given) $($BillTo.family) at the address: 
 $($BillTo.address.lines)$($BillTo.address.city)
$($BillTo.address.state)
($($BillTo.address.postal))" 
```

...and whatever else in terms of accessing the data via dot notation that you care to try. 
The problem is that the YAML deserialiser creates NET objects, which is entirely correct and useful, but it is just more convenient to have PowerShell objects to make them full participants.

## Refining the Deserializing process. 

Generally speaking, a good library for parsing and emitting data documents does so in two phases. The main work on a string containing XML, YAML, CSV or JSON is to create a representational model. The second phase is to turn that representational model into real data structures that are native to your computer language. 

In the case of YAML, you can have several separate documents in a single YAML string so the parser will return a representational model for every data document within the file:. Each representational model consists of a number of ‘nodes’. All you need to do is to examine each node recursively to create a data object. Each node contains the basics: the style, tag and anchor. The mapping-style of the node is the way it is formatted in the document, The anchor is used where a node references another node to get its value, and a tag tells you what sort of data type it needs, explicitly. This will include ‘omap’, ‘seq’ or ‘map’, where the node contains a list, sequence or a dictionary, or ‘float’, ‘int’, ‘null’, ‘bool’ or ‘str’ if it has a simple value. You can specify your own special data, such as coordinates, table data or whatever you wish.

A typical YAML library will parse the presentation stream and compose the Representation Graph. The final input process is to construct the native data structures from the YAML representation. The advantage of this is that you can then specify how your special data types are treated in the conversion process. Because YAML is a superset of JSON, you still have to allow untyped values that then have to be checked to see what sort of data it contains.

Here is a routine that takes as a parameter a representational model and converts it into a PowerShell object. It is easy to check this by converting the resulting object to XML or JSON or even YAML.

```powershell
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
    { $TheObject = $theNode.Value } #so you return its value
    elseif ($TheTypeOfNode -eq 'YamlSequenceNode') #in which case you 
    { $TheObject = @(); $theNode | foreach{ $TheObject += ConvertFrom-YAMLDocument $_ } }
    else { Write-Verbose "Unrecognised token $TheTypeOfNode" }
    $TheObject
} 
```

In order to use this, all you need to do is to load the text of the YAML document into a YAML stream.

```powershell
  $stringReader = new-object System.IO.StringReader([string]$yamlString)
  $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
  $yamlStream.Load([System.IO.TextReader]$stringReader)
  ConvertFrom-YAMLDocument ($yamlStream.Documents[0])
```

So there you have it. We now wrap this last code in a function and we have a PowerShell module that we can use whenever we need to parse YAML. I won’t bother to list that here as I’ve put it on GitHub for you. 

I also have added ConvertTo-YAML, because this is handy if you need plenty of control over the way that your PowerShell objects are serialized. Some of these objects are very unwieldy, with a lot of irrelevant information, and if you try serializing them without any sort of filtering, you will accidentally contribute to the Big Data crisis.

Last but most important, I wanted a way of loading a third party .net library into a module from nuget. I therefore added a function to add the library using add-Type, but which checked to make sure that everything was there first, and load it in the right place if it wasn’t. You can call it explicitly to check that you have the latest version of YamlDotNet. If it breaks something, you just delete the directory that it put the new version in: The module always loads the latest version in the YamlDotNet directory that it can find.

```powershell
Initialize-PsYAML_Module $True
```

## Simple Example of use
Here is a way of producing a YAML result from any SQL expression on a database

```powershell
import-module psyaml
$SourceTable = 'production.location'
$Sourceinstance = 'YourInstanceName'
$Sourcedatabase = 'Adventureworks'

$SourceConnectionString = "Data Source=$Sourceinstance;Initial Catalog=$Sourcedatabase;Integrated Security=True"
$sql = "select * FROM $SourceTable"
$result = @()
try
{
    $sourceConnection = New-Object System.Data.SqlClient.SQLConnection($SourceConnectionString)
    $sourceConnection.open()
    $commandSourceData = New-Object system.Data.SqlClient.SqlCommand($sql, $sourceConnection)
    $reader = $commandSourceData.ExecuteReader()
    $Counter = $Reader.FieldCount
    while ($Reader.Read())
    {
        $tuple = @{ }
        for ($i = 0; $i -lt $Counter; $i++)
        {
        $tuple."$($Reader.GetName($i))" = "$(if ($Reader.GetFieldType($i).Name -eq 'DateTime')
                { $Reader.GetDateTime($i) }
                else { $Reader.GetValue($i) })";
        }
        $Result += $tuple
    }
    YAMLSerialize $result
}
catch
{
    $ex = $_.Exception
    Write-Error "whilst opening source $Sourceinstance . $Sourcedatabase . $SourceTable : $ex.Message"
}
finally
{
    $reader.close()
}
```

This will give the result (just the first three rows)

```powershell
- CostRate: 0.0000
  ModifiedDate: 06/01/1998 00:00:00
  Name: Tool Crib
  Availability: 0.00
  LocationID: 1
- CostRate: 0.0000
  ModifiedDate: 06/01/1998 00:00:00
  Name: Sheet Metal Racks
  Availability: 0.00
  LocationID: 2
- CostRate: 0.0000
  ModifiedDate: 06/01/1998 00:00:00
  Name: Paint Shop
  Availability: 0.00
  LocationID: 3
#and so on...  
```
## So what is the point of all this?
Besides the fact that it is an intuitive way of representing data, one of the most important advantages of YAML over JSON is that YAML allows you to [specify your data type](http://www.yaml.org/type). You don't need to in YAML, but it can resolve ambiguity. I've implemented the standard YAML scalar tags of [timestamp](http://www.yaml.org/type/timestamp.html), [binary](http://www.yaml.org/type/binary.html), [str](http://www.yaml.org/type/str.html), [bool](http://www.yaml.org/type/bool.html), [float](http://www.yaml.org/type/float.html), [int](http://www.http://yaml.org/type/int.html) and [null](http://www.yaml.org/type/null.html). If there is no scalar tag, I also autodetect a string to try to get it to the right data type. 

YAML also has a rather crude way of allowing you to represent relational data by means of [node](http://www.yaml.org/spec/1.2/spec.html#node//) Anchors. These A have an '&' prefix. An [alias node](http://www.yaml.org/spec/1.2/spec.html#alias//) can then be used to indicate additional inclusions of the anchored node. It means that you don't have to repeat nodes in a document. You just write it once and then refer to the node by its anchor.

I find YAML to be very useful. What really convinces me of the power of YAML is to be able to walk the representational model to do special-purpose jobs such as processing hierarchical data to load into SQL. It is at that point that I finally decided that YAML had a lot going for it as a format of data document.
# Specify Module Name
$ModuleName = "PSYaml"

# Determine our installation path based on where "My Documents" is located
$InstallPath = $env:PSModulePath.split(";") | Where-Object {$_ -match "My Documents" -or $_ -match "Documents"}

# Specify deploy task
Deploy "Install $ModuleName"
{
    By Filesystem
    {
        FromSource $ModuleName
        To "$($InstallPath)\$($ModuleName)"
        WithOptions @{
                        # This overrides any existing content
                        Mirror = $True
                     }
    }
}

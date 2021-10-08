Param(
    [Parameter(Mandatory = $true)]
    [string]$DWHname,

    [Parameter(Mandatory = $true)]
    [string]$environment,

    [Parameter(Mandatory = $true)]
    [string]$name
)

$data=@"
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="Current" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <IncludeCompositeObjects>True</IncludeCompositeObjects>
    <TargetDatabaseName>$name</TargetDatabaseName>
    <DeployScriptFileName>name-$environment.sql</DeployScriptFileName>
    <ProfileVersionNumber>1</ProfileVersionNumber>
    <TargetConnectionString>$connection string</TargetConnectionString>
  </PropertyGroup>
</Project>
"@

New-Item -Path . -Name "sql-publish.xml" -ItemType "file" -Value $data

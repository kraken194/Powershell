param (
    [Parameter(Mandatory = $true)]
    [string]$SiteName,

    [Parameter(Mandatory = $true)]
    [string]$AppPoolName,

    [Parameter(Mandatory = $true)]
    [string]$ArtifactStagingDirectory,

    [Parameter(Mandatory = $true)]
    [string]$CI_PROJECT_DIR
)

$UserName = 'admin'
$Password = 'Password'
$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $securePassword
Invoke-Command -ComputerName 20.73.47.000 -Credential $Credential -FilePath  -ArgumentList $SiteName,$AppPoolName,$ArtifactStagingDirectory,$CI_PROJECT_DIR
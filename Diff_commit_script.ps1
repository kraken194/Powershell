#app - application ID
#clsec - client secret
#tenant - tenant ID
#commit - last commit from where need to find changes
#rootfolder - folder where the changes should tracked

# -app "$(client_id)" -clsec "$(client_secret)" -tenant "$(tenant_id)" -commit "$(powerBiCommitHash)" -rootfolder "PROD/"

# нужно один раз запустить с старой пайплайн ИД и после изменить на новую
param (
    [Parameter(Mandatory = $false)] # TRUE in prod
    [string] $PAT = "personal access tocken",

    [Parameter(Mandatory = $false)] # TRUE in prod
    [ValidateSet("DEV", "PROD")]
    [string]$Environment = "DEV", # PROD or DEV

    [Parameter(Mandatory = $false)]
    $applicationId, 

    [Parameter(Mandatory = $false)]
    $clientSecret, 

    [Parameter(Mandatory = $false)]
    [string]$tenant
)

try {    
# Create header with Personal Access Tocken
$AuthTocken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
$Header = @{
    "authorization" = "Basic $AuthTocken"
}

#region    API call function
function invokeAPI {
    param (
        [Parameter(Mandatory = $false)]
        [string]$buildId
    )
    $result = Invoke-RestMethod -ContentType "application/json" -Headers $header -Method "GET" -Uri ""
    return $result
}
#endregion API call function

# Get list with all runs for pipeline '[prod/dev] power BI'
$runsList = invokeAPI -buildId $null 

$currentRun = $runsList.value.id[0]  # Current run ID
$previousRun = $runsList.value.id[1] # Previous run ID

# Get commit id's from pipeline
$currentcommitId = invokeAPI -buildId $currentRun
$currentCommitId = $currentcommitId.resources.repositories.__designer_repo.version

$previousCommitId = invokeAPI -buildId $previousRun
$previousCommitId = $previousCommitId.resources.repositories.__designer_repo.version 

# Get git differences between deployments 

$changesFileList = git diff --name-only $currentCommitId $previousCommitId
$filesToDeploy = ($changesFileList | Where-Object { $_ -like "PowerBIReports/$Environment/*" }) # $Environment

# connect to Azure Power BI (to all PROD and DEV spaces)
Write-Host "Connection to Azure Power BI"
$clientSecret = $clientSecret | ConvertTo-SecureString -AsPlainText -Force # Need to pass from devops secret variable
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $applicationId, $clientSecret 
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenant -ErrorAction Stop

########## Information block #####################
Write-Host "`n----> Information about deployment <----`n"
Write-Host "Current environment > $Environment"
Write-Host "Current commit  - $currentCommitId ; Currnet run id - $currentRun"
Write-Host "Previous commit - $previousCommitId ; Previous run id - $previousRun`n"
Write-Host "Will be deployed files below:"
foreach ($file in $filesToDeploy) {
    Write-Host "$file"
}
Write-Host "`n----> End of information <----`n"

#################### deploy script ###############
Write-Host "`n================START Deploy===================`n"


if ($Environment -eq "PROD") {

    $filesToDeploy | ForEach-Object { 

        $reportName = ($_ -replace( "PowerBIReports/$Environment/" , '') -replace ".*?/" -replace '.pbix','')
        Write-Host "Report name     : $reportName"
        Write-Host "Full path       : $_"

        $WorkspaceName = $_ -replace ( "PowerBIReports/$Environment/" , '') -replace "/.*"
        Write-Host "Workspace name  : $WorkspaceName"

        $WorkspaceID = (Get-PowerBIWorkspace -Name $WorkspaceName).id #get workspace id
        Write-Host "Workspace id is : $WorkspaceID`n"
        
        Write-Host "Publishing Report"
        New-PowerBIReport -Path "./$_" -WorkspaceId $WorkspaceId -ConflictAction CreateOrOverwrite
    }

}
elseif ($Environment -eq "DEV") {
    $filesToDeploy | ForEach-Object {
          
        $reportName = ($_ -replace( "PowerBIReports/$Environment/" , '') -replace ".*?/" -replace '.pbix','')
        Write-Host "Report name     : $reportName"
        Write-Host "Full path       : $_"

        $WorkspaceName = $_ -replace ( "PowerBIReports/$Environment/" , '') -replace "/.*"
        Write-Host "Workspace name  : $WorkspaceName"

        $WorkspaceId = (Get-PowerBIWorkspace -Name $WorkspaceName).id #get workspace id
        Write-Host "Workspace id is : $WorkspaceId`n"

        Write-Host "Publishing Report"
        New-PowerBIReport -Path "./$_" -WorkspaceId $WorkspaceId -ConflictAction CreateOrOverwrite

    }
}
else {
    Write-Error "Incorrect environment found > $Environment <, check inputted environment"
}

Write-Host "================FINISH==================="
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Unexpected error with script execution, please check script. Error: $errorMessage"
    throw $_
}

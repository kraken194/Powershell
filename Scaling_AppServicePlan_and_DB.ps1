Param
(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateSet("F1", "B1", "B2", "B3", "P1v2", "P2v2", "P3v2", "P1v3", "P2v3", "P3v3", "S1", "S2", "S3")]
    [string]$AppServicePlanSkuName,

    [Parameter(Position = 2, Mandatory = $true)]
    [string]$ServerName,

    [Parameter(Position = 3, Mandatory = $true)]
    [ValidateSet( "Basic", "S0", "S1", "S2", "S3", "S4", "S6", "S7", "S9", "S12")]
    [string]$DBSkuName
)  
#region start timer
$startTime = Get-Date
Write-Output "START - $startTime"
#endregion

#region Connection to Azure account
try {
    $ServicePrincipalID = ""
    $ServicePrincipalKey = ""
    $AzureTenantId = ""    
    $SPkey = ConvertTo-SecureString -String $ServicePrincipalKey -AsPlainText -Force
    Write-Host "Connecting to Azure Account"
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServicePrincipalID, $SPkey
    Connect-AzAccount -TenantId $AzureTenantId -Credential $Credential -ServicePrincipal -ErrorAction Stop 
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Connection failed. $errorMessage"
    throw $_
}   
#endregion

#region App Service Plane scale configuration
try {
    $appServicePlanList = Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName
    foreach ($appservice in $appServicePlanList) {
        Write-Console "Scaling proccess started for App Service Plan "$appservice.Name" in RG "$ResourceGroupName" for Tier "$AppServicePlanSkuName""
        Set-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Tier $AppServicePlanSkuName  -Name $appservice.Name
    } 
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Exeption in region App Service Plane scale configuration. $errorMessage"
    throw $_
}
#endregion

$middleTime = Get-Date
Write-Output "$middleTime - AppServicePlan configuration completed, Database configuration started"

#region Databases scale configuration
try {
    $SqlDatabaseList = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName "scale*"
    foreach ($sqlDatabase in $SqlDatabaseList) {
        Write-Console "Scaling proccess started for Database "$sqldDtabase.DatabaseName" in RG "$ResourceGroupName" for Tier "$DBSkuName""
        Set-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $sqldDtabase.DatabaseName -RequestedServiceObjectiveName $DBSkuName
    } 
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Exeption in region Databases scale configuration. $errorMessage"
    throw $_
}
#endregion

#region end timer
$endTime = Get-Date
Write-Output "END - $endTime"
#endregion
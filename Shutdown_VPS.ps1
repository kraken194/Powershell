Param
(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Position = 1, Mandatory = $false)]
    [ValidateSet("Environment")] 
    [string]$TagName,
    
    [Parameter(Position = 2, Mandatory = $false)]
    [ValidateSet("dev", "test", "prod")] 
    [string]$TagValue,

    [Parameter(Position = 3, Mandatory = $false)]
    [ValidateSet("turn_on", "turn_off")]
    [string]$status
)

$startTIme = Get-Date
Write-Output "START - $startTIme"

$resources = Get-AzResource -ResourceGroupName $ResourceGroupName -TagName $TagName -TagValue $TagValue -ResourceType Microsoft.Compute/virtualMachines 

if (($ResourceGroupName -eq "`0") -or ($ResourceGroupName -eq "")) {
    Write-Error "===> ResourceGroupName is null or empty"
}
elseif (($TagName -eq "`0") -or ($TagName -eq "")) {
    Write-Error "===> TagName is null or empty"
}
elseif (($TagValue -eq "`0") -or ($TagValue -eq "")) {
    Write-Error "===> TagValue is null or empty"
}
elseif (($status -eq "`0") -or ($status -eq "")) {
    Write-Error "===> status is null or empty"
}
else {
    switch ($status) {
        turn_on { 
            ForEach ($resource in $resources) {
                Write-Host "===> Turned On $($resource.Name)"
                Start-AzVM -Name $resource.Name -ResourceGroupName $ResourceGroupName
            }
        }
        turn_off { 
            ForEach ($resource in $resources) {
                Write-Host "===> Shutting down $($resource.Name)"
                Stop-AzVM -Name $resource.Name -ResourceGroupName $ResourceGroupName -Force
            }
        }    
    }    
}

$endTIme = Get-Date
Write-Output "END - $endTIme"

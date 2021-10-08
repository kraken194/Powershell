# Remove resources using id 
Param(
    [string]$ResourceGroupName,
    [string]$TargetName
)

Write-Host "--------------------" 
$resources = Get-AzResource -ResourceGroupName $ResourceGroupName | Where-Object ResourceId -like "*$($TargetName)*"

Foreach ($resource in $resources) {   
    Write-Host "Target Recource Name - $($resource.Name)"
    Write-Host "Resource Id - $($resource.ResourceId)"
    Remove-AzResource -ResourceId $resource.ResourceId -Force
    Write-Host "---"
}
Write-Host "Resource removed with pattern >>*+$($TargetName)*<<"
Write-Host "--------------------"
 
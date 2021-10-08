
$filesToChange = Get-ChildItem -Exclude dir1, dir2 | foreach-object { Get-ChildItem $_ -File -Recurse } | Where-Object { $_.Name -notlike "*.ps1" -and $_.Name -like "*.json" }

foreach ($file in $filesToChange) {

    $fileObjects = Get-Content $file | ConvertFrom-Json # Convert from json to Object

    $parametrObjects = $fileObjects.parameters # Get Parametrs content from file

    $allParametrsList = $fileObjects.parameters | Get-Member | Where-Object { $_.Name -notlike "Equals" -and $_.Name -notlike "GetHashCode" -and $_.Name -notlike "GetType" -and $_.Name -notlike "ToString" } | Select-Object -Property Name

    foreach ($name in $allParametrsList.Name) {

        $defaultValue = $parametrObjects | ForEach-Object { $_.$name.defaultValue } 
        $replacedDefaultValue = $defaultValue -creplace 'dev', 'prod'
        ( Get-Content $file -Raw ) -creplace "$defaultValue", "$replacedDefaultValue" | Set-Content $file
        Write-Host "$defaultValue >>> $replacedDefaultValue"

    }

    # remove empty stings 
    (Get-Content $file) | Where-Object { $_.trim() -ne "" } | Set-Content $file

}





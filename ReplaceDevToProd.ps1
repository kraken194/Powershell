param (
    [Parameter(Mandatory)]
    [string] $environment
)

$modifiedFilesList = New-Object System.Collections.Generic.List[string];
$files = Get-ChildItem -Exclude dir1,dir2 | foreach-object { Get-ChildItem $_ -File -Recurse } | Where-Object {$_.Name -notlike "*.ps1" -and $_.Name -like "*.json" };

foreach ($file in $files.FullName) {
    #create a new list to save content
    $newContent = New-Object System.Collections.Generic.List[string];

    foreach ($line in (Get-Content $file)) {
        #save line for comparison
        $original = $line; 
        $modified = $line -replace "dev", "$environment";
        if ($original -ne $modified) {
            #line has changed (skip the case sensitive search, cause we are changing a token here. Case sensitive switch is '-cne')
            $line = $modified;
            $modifiedFilesList.Add($file); #save the file as modified
        }
        $newContent.Add($line); #add content to list that will be saved to file
    }
    $newContent | Set-Content $file; #set content of file
    $changesCounter = $newContent.Count
}


# get only unique files from changet files list
$uniquemodifiedFilesList = $modifiedFilesList | Get-Unique

if ($modifiedFilesList.Count -gt 0) {
    Write-Output "====================================="
    Write-Output "Files changed: `n$([string]::Join("`n", $uniquemodifiedFilesList ))";
    Write-Output "Total changed strings:$changesCounter "
    Write-Output "====================================="
}
else {
    Write-Output "No files changed";
}
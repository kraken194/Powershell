

$file="VersionContainer.txt"

$in=Get-Content $file

$in | ForEach-Object {$_ -replace '[0-9][0-9][0-9][0-9]','2'} | out-file newvers.txt -Force 
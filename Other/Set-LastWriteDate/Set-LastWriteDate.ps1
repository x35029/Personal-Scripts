$dir = "H:\Sync\02 - Terminal Server\SCOM"
$folderArray = Get-ChildItem $dir -recurse | ? { !$_.psiscontainer }
foreach ($file in $folderArray)
{
    $file.LastWriteTime = get-date 
    write-host $file.LastWriteTime," - ",$file.FullName
}
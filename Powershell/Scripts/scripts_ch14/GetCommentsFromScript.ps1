# -----------------------------------------------------------------------------
# Script: GetCommentsFromScript.ps1
# Author: ed wilson, msft
# Date: 09/08/2013 14:03:16
# Keywords: documentation
# comments: Comments
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 14
# -----------------------------------------------------------------------------

Function Get-FileName
{
 Param ($Script)
 $OutPutPath = [io.path]::GetTempPath()
 Join-Path -path $OutPutPath -child "$(Split-Path $script -leaf).txt"
} #end Get-FileName

Function Remove-OutPutFile($OutPutFile)
{
  if(Test-Path -path $OutPutFile) 
    {
       $Response = Read-Host -Prompt "$OutPutFile already exists. Do you wish to delete it <y / n>?"
       if($Response -eq "y")
         { Remove-Item $OutPutFile | Out-Null }
       ELSE 
         {
           if(Test-Path -path "$OutPutFile.old") { Remove-Item -Path "$OutPutFile.old" }
           Rename-Item -path $OutPutFile -newname  "$(Split-Path $OutPutFile -leaf).old" -Force
          }
    }
} #end Remove-OutPutFile

Function Get-Comments
{
 Param ($Script, $OutPutFile)
 Get-Content -path $Script |
 Foreach-Object { 
    If($_ -match '^\#')
     { $_  | 
      Out-File -FilePath $OutPutFile -append } 
  } #end Foreach
} #end Get-Comments

Function Get-OutPutFile($OutPutFile)
{
 Notepad $OutPutFile
} #end Get-OutPutFile

# *** Entry point to script ***

$script = 'C:\scriptfolder\Get-ModifiedFilesUsePipeline.ps1'
$OutPutFile = Get-FileName($script)
Remove-OutPutFile($OutPutFile)
Get-Comments -script $script -outputfile $OutPutFile
Get-OutPutFile($OutPutFile) 

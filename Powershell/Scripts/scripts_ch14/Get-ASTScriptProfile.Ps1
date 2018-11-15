#requires -version 3.0

<#
.Synopsis
Profile a PowerShell Script
.Description
This script will parse a PowerShell script using the AST to identify elements 
and any items that might be dangerous. The output is a text report which by 
default is turned into a help topic stored in your Windows PowerShell folder
under Documents.

DETAILS
The script takes the name of a script to profile. You can specify a ps1 or 
psm1 filename. Using the AST the script will prepare a text report showing 
you any script requirements, script parameters, commands and type names. You 
will see all commands used including those that can't be resolved as well as 
those that I thought might be considered potentially dangerous such as cmdlets 
that use the verbs Remove or Stop. Because some people might invoke methods 
from .NET classes directly I’ve also captured all typenames. Most of them will
probably be related to parameters but as least you'll know what to look for. 

The report won’t detail parameters from nested functions but you'll still see 
what commands they will use. The script uses Get-Command to identify commands 
which might entail loading a module. Most of the time this shouldn't be an 
issue but you still might want to profile the script in virtualized or test 
environment. 

Any unresolved command you see is either from a module that couldn't be loaded
or it might be an internally defined command. Once you know what to look for 
you can open the script in your favorite editor and search for the mystery 
commands.
 

.Example
PS C:\> c:\scripts\Get-ASTScriptProfile c:\download\new.ps1 
.Link
Get-Command
Get-Alias
#>

[cmdletbinding()]
Param(
[Parameter(Position=0,Mandatory,HelpMessage="Enter the path of a PowerShell script")]
[ValidateScript({Test-Path $_})]
[string]$Path
)

Write-Verbose "Starting $($myinvocation.MyCommand)"
#need to resolve full path
$Path = (Resolve-Path -Path $Path).Path
Write-Verbose "Analyzing $Path"

Write-Verbose "Parsing File for AST"
New-Variable astTokens -force
New-Variable astErr -force

$AST = [System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$astTokens,[ref]$astErr)

$report=@"
Script Profile report for: $Path

"@

Write-Verbose "Getting requirements and parameters"
$report+=@"

******************
*  Requirements  *
******************
$(($ast.ScriptRequirements | out-string).Trim())

******************
*  Parameters    *
******************
$(($ast.ParamBlock.Parameters | 
 Select Name,DefaultValue,StaticType,Attributes |
 Format-Table -autosize | Out-String).Trim())
 
"@

Write-Verbose "Getting all command elements"

$commands = @()
$unresolved = @()

$genericCommands = $astTokens | 
where {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'generic'} 

$aliases = $astTokens | 
where {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'identifier'} 

Write-Verbose "Parsing commands"
foreach ($command in $genericCommands) {
    Try {
       $commands+= Get-Command -Name $command.text -ErrorAction Stop
    }
    Catch {
      $unresolved+= $command.Text
    }
}

foreach ($command in $aliases) {
Try {
       $commands+= Get-Command -Name $command.text -erroraction Stop |
       foreach { 
         #get the resolved command
         Get-Command -Name $_.Definition  
       }
    }
    Catch {
        $unresolved+= $command.Text
    }
}


Write-Verbose "All commands"
$report+=@"

******************
*  All Commands  *
******************
$(($Commands | Sort -Unique | Format-Table -autosize | Out-String).Trim())

"@

Write-Verbose "Unresolved commands"
$report+=@"

******************
*  Unresolved    *
******************
$($Unresolved | Sort -Unique | Format-Table -autosize | Out-String)
"@

Write-Verbose "Potentially dangerous commands"
#identify dangerous commands
$danger="Remove","Stop","Disconnect","Suspend","Block",
"Disable","Deny","Unpublish","Dismount","Reset","Resize",
"Rename","Redo","Lock","Hide","Clear"

$danger = $commands | where {$danger -contains $_.verb}

#get type names, some of which may come from parameters
Write-Verbose "Typenames"
$report+=@"

******************
*  TypeNames     *
******************
$($asttokens | where {$_.tokenflags -eq 'TypeName'} | 
Sort @{expression={$_.text.toupper()}} -unique | 
Select -ExpandProperty Text | Out-String)
"@

$report+=@"

******************
*  Warning       *
******************
$($danger | Format-Table -AutoSize | Out-String)
"@

Write-Verbose "Display results"

#create a help topic file using the script basename
$basename = (Get-Item $Path).basename     
#stored in the Documents folder
$reportFile = Join-Path -Path "$env:userprofile\Documents" -ChildPath "$basename.help.txt"

#insert the Topic line so help recognizes it
"TOPIC" | Out-File -FilePath $reportFile -Encoding ascii
#create the report
$report | Out-File -FilePath $reportFile -Encoding ascii -Append

#view the report with Get-Help and -ShowWindow
Get-Help (Join-Path -Path "$env:userprofile\Documents" -ChildPath $basename) -ShowWindow

Write-Verbose "Profiling complete"
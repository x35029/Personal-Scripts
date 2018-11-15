# -----------------------------------------------------------------------------
# Script: GetRandomObject.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 18:42:18
# Keywords: cmdlet
# comments: CmdLet support
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 6
# -----------------------------------------------------------------------------
Function GetRandomObject($in,$count)
{
 $rnd = New-Object system.random
 for($i = 1 ; $i -le $count; $i ++)
 {
  $in[$rnd.Next(1,$a.length)]
 } #end for
} #end GetRandomObject

# *** entry point ***
$a = 1,2,3,4,5,6,7,8,9
$count = 3
GetRandomObject -in $a -count $count

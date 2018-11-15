# -----------------------------------------------------------------------------
# Script: Get-PowerShellRequirements.ps1
# Author: ed wilson, msft
# Date: 09/09/2013 15:39:54
# Keywords: install
# comments: requirements
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 1
# -----------------------------------------------------------------------------
Param([string[]]$computer = @($env:computername, "LocalHost"))
 foreach ($c in $computer)
  { 
    $o = Get-WmiObject win32_operatingsystem -cn $c
    switch ($o.version)
    {
        {$o.version -gt 6.2} {"$c is Windows 8 or greater"; break}
        {$o.version -gt 6.1} 
          {
           If($o.ServicePackMajorVersion -gt 0){$sp = $true}
           If(Get-WmiObject Win32_Product -cn $c | 
              where { $_.name -match '.NET Framework 4.5'}) {$net = $true }
           If($sp -AND $net) { "$c meets the requirements for PowerShell 3" ; break}
           ElseIF (!$sp) {"$c needs a service pack"; break}
           ELSEIF (!$net) {"$c needs a .NET Framework upgrade"} ; break}
        {$o.version -lt 6.1} {"$c does not meet standards for PowerShell 3.0"; break}
        Default {"Unable to tell if $c meets the standards for PowerShell 3.0"}
    }
  
  }

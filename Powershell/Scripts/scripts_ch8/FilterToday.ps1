# -----------------------------------------------------------------------------
# Script: FilterToday.ps1
# Author: ed wilson, msft
# Date: 08/28/2013 12:11:01
# Keywords: function
# comments: Understanding Filters
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 8
# -----------------------------------------------------------------------------
Filter IsToday
{
 Begin {$dte = (Get-Date).Date}
 Process { $_ | 
           Where-Object { $_.LastWriteTime -ge $dte }
         }
}

Get-ChildItem -Path C:\fso | IsToday

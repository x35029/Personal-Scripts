# -----------------------------------------------------------------------------
# Script: Get-WinFeatureServersWorkflow.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:58:14
# Keywords: workflow
# comments: workflow
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 22
# -----------------------------------------------------------------------------
workflow get-winfeatures
{
 Parallel {
    InlineScript {Get-WindowsFeature -Name PowerShell*}
    InlineScript {$env:COMPUTERNAME} 
    Sequence {
        Get-date 
        $PSVersionTable.PSVersion } }
}
# -----------------------------------------------------------------------------
# Script: Get-ClientInfoWorkflow.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 17:56:10
# Keywords: workflow
# comments: workflow
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 22
# -----------------------------------------------------------------------------
workflow get-clientInfo
{
 Parallel {
    InlineScript {$env:COMPUTERNAME} 
    Sequence {
        InlineScript {\\dc1\Share\ServerNameBios.ps1}
        Get-date 
        $PSVersionTable.PSVersion } }
}
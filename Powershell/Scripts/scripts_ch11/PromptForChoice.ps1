# -----------------------------------------------------------------------------
# Script: PromptForChoice.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 15:19:05
# Keywords: Input
# comments: Prompting for input
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 11
# -----------------------------------------------------------------------------
$caption = "No Disk"
$message = "There is no disk in the drive. Please insert a disk into drive D:"
$choices = [System.Management.Automation.Host.ChoiceDescription[]] `
@("&Cancel", "&Try Again", "&Ignore")
[int]$defaultChoice = 2
$choiceRTN = $host.ui.PromptForChoice($caption,$message, $choices,$defaultChoice)

switch($choiceRTN)
{
 0    { "cancelling ..." }
 1    { "Try Again ..." }
 2    { "ignoring ..." }
}

# -----------------------------------------------------------------------------
# Script: GetTwoLetterAliasCombinations.ps1
# Author: ed wilson, msft
# Date: 08/25/2013 12:52:56
# Keywords: Alias
# comments: Configuring a profile
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 5
# -----------------------------------------------------------------------------
$letterCombinations = $null
$asciiNum = 97..122
$letters = $asciiNum | ForEach-Object { [char]$_ }
Foreach ($1letter in $letters)
{
 Foreach ($2letter in $letters)
 {[array]$letterCombinations += "$1letter$2letter"} }
"There are " + ($letterCombinations | Measure-Object).count + 
" possible combinations"
"They are listed here: "
$letterCombinations

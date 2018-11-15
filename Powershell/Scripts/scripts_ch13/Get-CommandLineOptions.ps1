# -----------------------------------------------------------------------------
# Script: Get-CommandLineOptions.ps1
# Author: ed wilson, msft
# Date: 09/06/2013 19:04:11
# Keywords: Basic Syntax Checking
# comments: Test Script Harness
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 13
# -----------------------------------------------------------------------------
Function Get-CommandLineOptions
{
  
if($all) 
  {
    Get-Disk($computer)
    Get-Processor($computer)
    Get-Memory($computer)
    Get-Network($computer)
    Get-Video($computer)
     exit
  } #end all

if($disk) 
  {
    Get-Disk($computer)
  } #end disk

if($processor) 
  {
    Get-Processor($computer)
  } #end processor

if($memory) 
  {
    Get-Memory($computer)
  } #end memory

if($network) 
  {
    Get-Network($computer)
  } #end network

if($video) 
  {
    Get-Video($computer)
  } #end video
} #end function Get-CommandLineOptions

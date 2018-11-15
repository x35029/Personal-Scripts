<# 
.SYNOPSIS 
    A summary of what this script does 
    In this case, this script documents the auto-help text
    in PowerShell CTP 3 
    Appears in all basic, -detailed, -full, -examples 
.DESCRIPTION 
    A more in depth description of the script 
    Should give script developer more things to talk about 
    Hopefully this can help the community too 
    Becomes: "DETAILED DESCRIPTION" 
    Appears in basic, -full and -detailed 
.NOTES 
    Additional Notes, eg 
    File Name  : get-autohelp.ps1 
    Author     : Thomas Lee - tfl@psp.co.uk 
    Requires   : PowerShell V2 CTP3 
    Appears in -full  
.LINK 
    A hyper link, eg 
    http://www.pshscripts.blogspot.com/2008/12/get-autohelpps1.html 
    Becomes: "RELATED LINKS"  
    Appears in basic and -Full 
.EXAMPLE 
    The first example - just text documentation 
    You should provide a way of calling the script, plus
    any expected output, eg:
         C:\foo> .\get-autohelp.ps1 42
         The meaning of life is 42
    Appears in -detailed and -full 
.EXAMPLE 
    The second example - more text documentation 
    This would be an example calling the script differently. You
    have lots and lots, and lots of examples if this is useful. 
    Appears in -detailed and -full 
.INPUTTYPE 
   Documentary text, eg: 
   Input type  [Universal.SolarSystem.Planetary.CommonSense] 
   Appears in -full 
.RETURNVALUE 
   Documentary Text, e,g: 
   Output type  [Universal.SolarSystem.Planetary.Wisdom] 
   Appears in -full 
.COMPONENT 
   Not sure how to specify or use 
   Does not appear in basic, -full, or -detailed 
   Should appear in -component 
.ROLE  
   Not sure How to specify or use 
   Does not appear in basic, -full, or -detailed 
   Should appear with -role 
.FUNCTIONALITY 
   Not sure How to specify or use 
   Does not appear in basic, -full, or -detailed 
   Should appear with -functionality 
.PARAMETER foo 
   The .Parameter area in the script is used to derive the
   of the PARAMETERS in Get-Help output which documents the
   parameters in the param block. The section takes a
   value (in this case foo,  the name of the first actual
   parameter), and only appears if there is parameter of
   that name in the param block. Having a section for a
   parameter that does not exist generate no extra output
   of this section   
   Appears in -detailed, -full (with more info than in -det)
   Appears in -Parameter (need to specify the parameter name) 
.PARAMETER bar 
   Example of a parameter definition for a parameter that does not exist. 
   Does not appear at all. 
#> 
 
# Note above section does not contain entries for NAME, SYNTAX
# and REMARKS sections of in get-help output 
# 
# These sections appear as follows: 
# NAME    - generated from the name passed to get-help.  
# SYNTAX  - generated from param block details. 
# REMARKS - generated based on script name (e.g. what's shown in NAME)
#           inserted into some static text. 
# 
# Not sure how to generate/document -component, -role, -functionality 
# Not sure how to generate/use  -category 
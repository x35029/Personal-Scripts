#--------------------------------------------------------------------------------- 
#The sample scripts are not supported under any Microsoft standard support 
#program or service. The sample scripts are provided AS IS without warranty  
#of any kind. Microsoft further disclaims all implied warranties including,  
#without limitation, any implied warranties of merchantability or of fitness for 
#a particular purpose. The entire risk arising out of the use or performance of  
#the sample scripts and documentation remains with you. In no event shall 
#Microsoft, its authors, or anyone else involved in the creation, production, or 
#delivery of the scripts be liable for any damages whatsoever (including, 
#without limitation, damages for loss of business profits, business interruption, 
#loss of business information, or other pecuniary loss) arising out of the use 
#of or inability to use the sample scripts or documentation, even if Microsoft 
#has been advised of the possibility of such damages 
#--------------------------------------------------------------------------------- 

#requires -Version 2.0

Param
(
    [Parameter(Mandatory=$true)]
    [Alias('pin')]
    [String[]]$PinItems
)

$Shell = New-Object -ComObject Shell.Application
$Desktop = $Shell.NameSpace(0X0)

Foreach($item in $PinItems)
{
    #Verify the shortcut whether exists
    If(Test-Path -Path $item)
    {
        
        
        $itemLnk = $Desktop.ParseName($item)
        
        $Flag=0
	
        #pin application to windows Tasbar
        $itemVerbs = $itemLnk.Verbs()
        Foreach($itemVerb in $itemVerbs)
        {
            If($itemVerb.Name.Replace("&","") -match "Pin to Taskbar")
            {
                $itemVerb.DoIt()
				$Flag=1
            }
        }
		
		#get the name of item
        $itemName = (Get-Item -Path $item).Name
		
		If($Flag -eq 1)
        {
            Write-Host "Pin '$itemName' file to taskbar successfully." -ForegroundColor Green
        }
        Else
        {
            Write-Host "Failed to pin '$itemName' file to taskbar." -ForegroundColor Red
        }
     }
    Else
    {
        Write-Warning "Cannot find path '$item' because it does not exist."
    }
}

function Get-CMModule
{
    [CmdletBinding()]
    param()
    Try
    {
        Write-Verbose "Attempting to import SCCM Module"
        Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
        Write-Verbose "Successfully imported the SCCM Module"
    }
    Catch
    {
        Throw "Failure to import SCCM Cmdlets."
    } 
}
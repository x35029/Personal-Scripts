function Test-ConfigMgrAvailable
{
    [CMdletbinding()]
    Param
    (
    )
        try
        {
            if((Test-Module -ModuleName ConfigurationManager) -eq $false){throw "You have not loaded the configuration manager module please load the appropriate module and try again."}
            write-Verbose "ConfigurationManager Module is loaded"
            Write-Verbose "Checking if current drive is a CMDrive"
            if((Get-location).Path -ne (Get-location -PSProvider 'CmSite').Path){throw "You are not currently connected to a CMSite Provider Please Connect and try again"}
            write-Verbose "Succesfully validated connection to a CMProvider"
            write-verbose "Passed all connection tests"
            return $true
        }
        catch
        {
            $errorMessage = $_.Exception.Message
            write-error -Exception CMPatching -Message $errorMessage
            return $false
        }
}
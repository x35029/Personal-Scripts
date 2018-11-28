function Test-Module
{
    [CMdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$ModuleName
    )
    If(Get-Module -Name $ModuleName)
    {
        return $true
    }
    If((Get-Module -Name $ModuleName) -ne $true)
    {
        return $false
    }
}
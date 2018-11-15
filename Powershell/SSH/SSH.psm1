<#
    .SYNOPSIS
    Executes an SSH command using SSH.Net from http://sshnet.codeplex.com/

#>
function Invoke-SSHCommand {
    [CmdletBinding(DefaultParameterSetName='SpecifyConnectionFields', HelpUri='https://sshnet.codeplex.com/')]
    param(
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Port,

        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential,

        [Parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [String]
        $KeyString,

        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Connection
    )

    if($Connection) {
        $ComputerName = $Connection.ComputerName
        $Port = $Connection.Port
        $Password = $Connection.Password | ConvertTo-SecureString -asPlainText -Force
        if ($Connection.UserName -ne $null) { $Credential = New-Object System.Management.Automation.PSCredential($Connection.UserName, $Password)}
    }


    if(!$Port) {
        $Port = 22
    }

    if ($KeyString)
    {
        Write-Verbose "Using key file for authentication"
        $TempKeyFile = "$env:temp\id_rsa.key"
        Set-Content -Path $TempKeyFile -Value $KeyString  -Force | Write-Verbose
        $Key = New-Object Renci.SshNet.PrivateKeyFile($TempKeyFile)
        $SSHConnection = New-Object Renci.SshNet.SshClient($Computer, $Port, $Credential.UserName, $Key)
        Remove-Item -Path $TempKeyFile -force

    }
    else
    {
        Write-Verbose "Using password for authentication"
        $SSHConnection = New-Object Renci.SshNet.SshClient($ComputerName, $Port, $Credential.UserName, $Credential.GetNetworkCredential().Password)
    }

    $SSHConnection.Connect()
    $ResultObject = $SSHConnection.RunCommand($ScriptBlock.ToString())

    Write-Output $ResultObject
}

Export-ModuleMember *
function Initialize-KPNBartServiceClients {
    <#
    .SYNOPSIS
    Initializes the KPN Bart BulkCommand, Command and QueryService clients

    .DESCRIPTION
    Initializes the KPN Bart BulkCommand, Command and QueryService clients. This function creates three highlevel $script variables
    so that the clients can be used througout this module

    .PARAMETER UserName
    The UserName for the user that has administrative access to the KPN Bart environment

    .PARAMETER Password
    The password for the user

    .PARAMETER BaseUrl
    The BaseUrl to your KPN Bart enviromnemt
    #>
    [CmdletBinding()]
    param (
        [String]
        $Username,
        
        [String]
        $Password,

        [String]
        $BaseUrl
    )

    try {
        $CredPassword = ConvertTo-SecureString $Password -Force -AsPlainText;
        $credentials = [System.Management.Automation.PSCredential]::new($UserName, $CredPassword)
        $script:BulkCommandService = Initialize-KPNBartBulkCommandServiceClient -PSCredentials $credentials -Uri $BaseUrl
        $script:CommandService = Initialize-KPNBartCommandServiceClient -PSCredentials $credentials -Uri $BaseUrl
        $script:QueryService = Initialize-KPNBartQueryServiceClient -PSCredentials $credentials -Uri $BaseUrl
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
function Set-KPNBartUserType {
    <#
    .SYNOPSIS
    Converts a KPN Bart user to a specific type

    .DESCRIPTION
    Converts a KPN Bart user to a specific type

    .PARAMETER Identity
    The Identity of the user you want to convert. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [Parameter(Mandatory)]
        [string]
        $UserType
    )

    try {
        $convertUserCommand = [KPNBartConnectedServices.CommandService.ConvertUserCommand]::new()
        $convertUserCommand.ObjectIdentity = $Identity
        $convertUserCommand.TargetType = $UserType
        $null = $Script:CommandService.Execute($convertUserCommand)
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
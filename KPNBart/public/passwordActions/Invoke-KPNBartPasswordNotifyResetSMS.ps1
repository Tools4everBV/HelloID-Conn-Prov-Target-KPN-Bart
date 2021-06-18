function Invoke-KPNBartPasswordNotifyResetSMS {
    <#
    .SYNOPSIS
    Notifies the user that the password is reset

    .DESCRIPTION
    Notifies the user via SMS that the password is reset

    .PARAMETER Identity
    The Identity for the user you want notify. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $Identity
    )

    try {
        $resetPasswordSMSCommand = [KPNBartConnectedServices.CommandService.ResetPasswordSMSCommand]::new()
        $resetPasswordSMSCommand.ObjectIdentity = $Identity

        $returnObject = $Script:CommandService.Execute($resetPasswordSMSCommand)
        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
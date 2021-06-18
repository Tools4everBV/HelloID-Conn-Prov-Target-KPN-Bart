function Set-KPNBartPasswordChangeAtNextLogon {
    <#
    .SYNOPSIS
    Updates the password for a KPN Bart user

    .DESCRIPTION
    Updates the password for a KPN Bart user

    .PARAMETER Identity
    The Identity for the user you want to update. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity
    )

    try {
        $changePasswordAtNextlogon = [KPNBartConnectedServices.CommandService.SetChangePasswordNextLogonCommand]::new()
        $changePasswordAtNextlogon.UserIdentity = $Identity

        $null = $Script:CommandService.Execute($changePasswordAtNextlogon)               
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }   
    
}
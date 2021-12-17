function Set-KPNBartPushToAuthenticate {
    <#
    .SYNOPSIS
    Sets or updates PushToAuthenticate for a user in KPN Bart
    .DESCRIPTION
    Sets or updates PushToAuthenticate for a user in KPN Bart
    .PARAMETER Identity
    The Identity of the user for whom you want to update the resource access. This is the samAccountName in Active Directory
    .PARAMETER Set
    Determines if the PushToAuthenticate is enabled or not. This is either true of false
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]
        $Identity,
        [Boolean]
        $Set
    )
    process {
        if ($PSCmdlet.ShouldProcess("$Identity", "Setting PushToAuthenticate")) {
            try {
                $mobileAppCommand = [KPNBartConnectedServices.CommandService.SettMobileAppAuthenticationCommand]::new()
                $pushToAuthCommand = [KPNBartConnectedServices.CommandService.SetPushToAuthenticateCommand]::new()
                $objectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                $objectIdentity.IdentityType = [KPNBartConnectedServices.CommandService.IdentityType]::sAMAccountname
                $objectIdentity.Value = $Identity

                $mobileAppCommand.ObjectIdentity = $ObjectIdentity
                $mobileAppCommand.Set = $Set
                $null = $script:CommandService.Execute($mobileAppCommand)

                $pushToAuthCommand.ObjectIdentity = $ObjectIdentity
                $pushToAuthCommand.Set = $Set
                $null = $script:CommandService.Execute($pushToAuthCommand)
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}
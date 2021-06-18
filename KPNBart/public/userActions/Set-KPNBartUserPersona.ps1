function Set-KPNBartUserPersona {
    <#
    .SYNOPSIS
    Set or update a persona

    .DESCRIPTION
    Set or update a persona for the specified user in KPN Bart

    .PARAMETER Identity
    The Identity of the user for whom you want to update the persona. This is the Identity in Active Directory

    .PARAMETER Persona
    The persona you want to add to the user
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [String]
        $Persona
    )

    try {
        $setPersonaCommand = [KPNBartConnectedServices.CommandService.SetPersonaCommand]::new()
        $setPersonaCommand.ObjectIdentity = $Identity
        $setPersonaCommand.Persona = $Persona
        $null = $Script:CommandService.Execute($setPersonaCommand)
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
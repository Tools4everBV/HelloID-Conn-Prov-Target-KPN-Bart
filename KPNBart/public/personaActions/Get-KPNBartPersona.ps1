function Get-KPNBartPersona {
    <#
    .SYNOPSIS
    Retrieves all persona's from KPN Bart

    .DESCRIPTION
    Retrieves all persona's from KPN Bart
    #>
    [CmdletBinding()]
    param (
    )

    try {
        $userPersona = [KPNBartConnectedServices.QueryService.PersonaQuery]::new()
        $returnObject = $script:QueryService.Execute($userPersona)
        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
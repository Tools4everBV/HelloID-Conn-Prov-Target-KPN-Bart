function Get-KPNBartUser {
    <#
    .SYNOPSIS
    Retrieves a single or all users from KPN Bart

    .DESCRIPTION
    Retrieves a single or all users from KPN Bart

    .PARAMETER Identity
    The Identity of the user you want to retrieve. This is the Identity in Active Directory

    .PARAMETER Attributes
    The Attributes you want to return

    .PARAMETER Persona
    Retrieves only the users with the specified persona
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.QueryService.ObjectIdentity]
        $Identity,

        [String[]]        
        $Attributes,

        [String]
        $Persona
    )

    $returnObject = $null

    try {
        if ($PSBoundParameters.ContainsKey('Identity')){
            $adMultipleAtributeQuery = [KPNBartConnectedServices.QueryService.ADMultipleAttributeQuery]::new()
            $adMultipleAtributeQuery.ObjectIdentity = $Identity
            $adMultipleAtributeQuery.Attributes = $Attributes

            $returnObject = $script:QueryService.Execute($adMultipleAtributeQuery)

        }
        elseif ($PSBoundParameters.ContainsKey('Persona')){
            $personaQuery = [KPNBartConnectedServices.QueryService.UserQuery]::new()
            $personaQuery.Persona = $Persona

            $returnObject = $script:QueryService.Execute($personaQuery)
        }
        else {
            $usersMultipleAttributeQuery = [KPNBartConnectedServices.QueryService.UsersMultipleAttributeQuery]::new()
            $usersMultipleAttributeQuery.Attributes = $Attributes
            $usersMultipleAttributeQuery.SearchFilter = ''

            $returnObject = $script:QueryService.Execute($usersMultipleAttributeQuery)
        }
        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
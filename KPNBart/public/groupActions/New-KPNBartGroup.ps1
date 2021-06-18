function New-KPNBartGroup {
    <#
    .SYNOPSIS
    Creates a new KPN Bart group

    .DESCRIPTION
    Creates a new KPN Bart group

    .PARAMETER Name
    The Name for the group you want to create
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $Name
    )

    try {
        $createGroupCommand = [KPNBartConnectedServices.CommandService.CreateGroupCommand]::new()
        $createGroupCommand.Name = $Name

        $returnObject = $Script:CommandService.Execute($createGroupCommand)
        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
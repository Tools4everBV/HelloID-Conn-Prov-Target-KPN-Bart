function New-KPNBartUser {
    <#
    .SYNOPSIS
    Creates a new KPN Bart user

    .DESCRIPTION
    Creates a new user in KPN Bart

    .PARAMETER FirstName
    The FirstName for the user you want to create

    .PARAMETER LastName
    The LastName for the user you want to create

    .PARAMETER Password
    The Password for the user you want to create

    .PARAMETER UserPrincipalName
    The UserPrincipalName for the user you want to create. This is the same as the UserPrincipalName in Active Directory

    .PARAMETER DisplayName
    The DisplayName for the user you want to create. This is the same as the DisplayName in Active Directory

    .PARAMETER MiddleName
    The MiddleName for the user you want to create

    .PARAMETER SamAccountName
    The SamAccountName for the user you want to create. This is the same as the SamAccountName in Active Directory
    #>
    [CmdletBinding()]
    param (
        [String]
        $FirstName,

        [String]
        $LastName,

        [String]
        $Initials,

        [SecureString]
        $Password,

        [String]
        $UserPrincipalName,

        [String]
        $DisplayName,

        [String]
        $MiddleName,

        [String]
        $SamAccountName
    )

    try {
        $createUserCommand = [KPNBartConnectedServices.CommandService.CreateUserCommand]::new()
        $createUserCommand.FirstName = $FirstName
        $createUserCommand.LastName = $LastName
        $createUserCommand.Initials = $Initials
        $createUserCommand.Password = $Password
        $createUserCommand.UserPrincipalName = $UserPrincipalName
        $createUserCommand.MiddleName = $MiddleName
        $createUserCommand.SamAccountName = $SamAccountName

        $null = $Script:CommandService.Execute($createUserCommand)
        
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
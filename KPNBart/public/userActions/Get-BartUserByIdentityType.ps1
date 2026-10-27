function Get-BartUserByIdentityType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('DistinguishedName', 'Guid', 'SamAccountName', 'Sid', 'UserPrincipalName', 'MailAddress')]
        [string]
        $attribute,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $value
    )

    process {
        try {
            $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
            $queryObjectIdentity.IdentityType = $attribute
            $queryObjectIdentity.Value = $value
            [string[]]$objectAttributes = @($attribute, 'objectGuid')
            $account = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes $objectAttributes -ErrorAction Stop
            Write-Verbose 'BART identity lookup completed.'
            return $account
        } catch {
            $userNotFoundMessage = "Identity $value could not be found."
            if ($_.Exception.Message.Contains($userNotFoundMessage)) {
                Write-Verbose 'BART account was not found.'
                return $false
            }
            throw 'Get-KPNBartUser failed while retrieving the account. Check the BART query service availability and access permissions.'
        }
    }
}
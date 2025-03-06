#################################################################
# HelloID-Conn-Prov-Target-KPN-BART-RevokePermission-FunctionGroup
# PowerShell V2
#################################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Begin
try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account.id))) {
        throw 'The account reference could not be found'
    }

    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    Import-Module $actionContext.Configuration.ModuleLocation -Force
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    Write-Information "Verifying if a KPN-BART account for [$($personContext.Person.DisplayName)] exists"
    $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
    $queryObjectIdentity.IdentityType = 'Guid'
    $queryObjectIdentity.Value = $actionContext.References.Account.id
    $correlatedAccount = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes  ([string[]]($actionContext.Data.PSObject.Properties.name))

    if ($null -ne $correlatedAccount) {
        $action = 'RevokePermission'
        $dryRunMessage = "Revoke KPN-BART permission: [$($actionContext.References.Permission.DisplayName)] will be executed during enforcement"
    } else {
        $action = 'NotFound'
        $dryRunMessage = "KPN-BART account: [$($actionContext.References.Account.id)] for person: [$($personContext.Person.DisplayName)] could not be found, possibly indicating that it could be deleted, or the account is not correlated"
    }

    # Add a message and the result of each of the validations showing what will happen during enforcement
    if ($actionContext.DryRun -eq $true) {
        Write-Information "[DryRun] $dryRunMessage"
    }

    # Process
    if (-not($actionContext.DryRun -eq $true)) {
        switch ($action) {
            'RevokePermission' {
                Write-Information "Revoking KPN-BART permission: [$($actionContext.References.Permission.DisplayName)] - [$($actionContext.References.Permission.Reference)]"

                $userIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                if (![string]::IsNullOrEmpty($correlatedAccount.ObjectGUID)) {
                    $userIdentity.IdentityType = 'guid'
                    $userIdentity.Value = $correlatedAccount.ObjectGUID
                } 
            
                $resourceIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                $resourceIdentity.IdentityType = 'guid'
                $resourceIdentity.Value = "$($actionContext.References.Permission.Reference)"
                $ResourceAuthorization = [KPNBartConnectedServices.CommandService.ResourceAuthorizationEnum]::Access

                Set-KPNBartResourceAccess -ResourceAuthorization $ResourceAuthorization -Identity $userIdentity -Add $false -ResourceIdentity $resourceIdentity

                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = "Revoke permission [$($actionContext.References.Permission.DisplayName)] was successful"
                        IsError = $false
                    })
            }

            'NotFound' {
                $outputContext.Success  = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = "KPN-BART account: [$($actionContext.References.Account)] for person: [$($personContext.Person.DisplayName)] could not be found, possibly indicating that it could be deleted, or the account is not correlated"
                        IsError = $false
                    })
                break
            }
        }
    }
} catch {
    $outputContext.success = $false
    $ex = $PSItem

    # TEMP code
    Write-Warning "$($ex.Exception.message)"
    Write-Warning "$($ex.Exception.InnerException.message)"
    Write-Warning "$($ex.Exception.InnerException.InnerException.message)"

    $auditMessage = "Could not create or correlate KPN-Bart account. Error: $($ex.Exception.Message)"
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"

    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}
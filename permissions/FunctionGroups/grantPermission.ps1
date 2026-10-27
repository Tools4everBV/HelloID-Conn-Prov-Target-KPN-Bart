################################################################
# HelloID-Conn-Prov-Target-KPN-BART-GrantPermission-FunctionGroup
# PowerShell V2
################################################################

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
    $action = 'GrantPermission'
    $dryRunMessage = "Grant KPN-BART permission: [$($actionContext.References.Permission.DisplayName)] will be executed during enforcement"

    # Add a message and the result of each of the validations showing what will happen during enforcement
    if ($actionContext.DryRun -eq $true) {
        Write-Information "[DryRun] $dryRunMessage"
    }

    # Process
    if (-not($actionContext.DryRun -eq $true)) {
        switch ($action) {
            'GrantPermission' {
                Write-Information "Granting KPN-BART permission: [$($actionContext.References.Permission.DisplayName)] - [$($actionContext.References.Permission.Reference)]"

                $resourceGuid = [guid]::Empty
                if (-not [guid]::TryParse([string]$actionContext.References.Permission.Reference.Reference, [ref]$resourceGuid)) {
                    throw 'The function group permission reference does not contain a valid GUID.'
                }

                $userIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                $userIdentity.IdentityType = 'GUID'
                $userIdentity.Value = $actionContext.References.Account.id

                $resourceIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                $resourceIdentity.IdentityType = 'guid'
                $resourceIdentity.Value = $resourceGuid.ToString()
                $ResourceAuthorization = [KPNBartConnectedServices.CommandService.ResourceAuthorizationEnum]::Access

                Set-KPNBartResourceAccess -ResourceAuthorization $ResourceAuthorization -Identity $userIdentity -Add $true -ResourceIdentity $resourceIdentity

                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = "Grant permission [$($actionContext.References.Permission.DisplayName)] was successful"
                        IsError = $false
                    })
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
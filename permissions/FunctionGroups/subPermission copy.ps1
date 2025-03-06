#########################################################
# HelloID-Conn-Prov-Target-{connectorName}-SubPermissions
# PowerShell V2
#########################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

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
    $correlatedAccount = Get-KPNBartUser -Identity $queryObjectIdentity

    # Collect current permissions
    $currentPermissions = $correlatedAccount.functionGroups

    # Collect desired permissions
    $desiredPermissions = [System.Collections.Generic.List[Object]]::new()
    foreach ($contract in $contractsInScope) {
        if ($contract.Organization) {
            $desiredPermissionObject = [PSCustomObject]@{
                displayname = $contract.Organization.Name
                id          = $contract.Organization.Id
            }
            $desiredPermissions.Add($desiredPermissionObject)
        }
        if ($contract.Division) {
            $desiredPermissionObject = [PSCustomObject]@{
                displayname = $contract.Division.Name
                id          = $contract.Division.Id
            }
            $desiredPermissions.Add($desiredPermissionObject)
        }
        if ($contract.Department) {
            $desiredPermissionObject = [PSCustomObject]@{
                displayname = $contract.Department.Name
                id          = $contract.Department.Id
            }
            $desiredPermissions.Add($desiredPermissionObject)
        }
    }

    # Process current permissions to revoke
    $newCurrentPermissions = @{}
    if ($currentPermissions) {
        foreach ($permission in $currentPermissions) {
            if (-Not $desiredPermissions.ContainsValue($permission.DisplayName)) {
                if (-Not($actionContext.DryRun -eq $true)) {
                    try {
                        $userIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        if (![string]::IsNullOrEmpty($correlatedAccount.ObjectGUID)) {
                            $userIdentity.IdentityType = 'guid'
                            $userIdentity.Value = $correlatedAccount.ObjectGUID
                        }

                        $resourceIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $resourceIdentity.IdentityType = 'guid'
                        $resourceIdentity.Value = $permission.Id
                        $ResourceAuthorization = [KPNBartConnectedServices.CommandService.ResourceAuthorizationEnum]::Access

                        Set-KPNBartResourceAccess -ResourceAuthorization $ResourceAuthorization -Identity $userIdentity -Add $false -ResourceIdentity $resourceIdentity
                        $newCurrentPermissions[$permission.Name] = $permission.Value

                        $outputContext.Success = $true
                        $outputContext.AuditLogs.Add([PSCustomObject]@{
                                Message = "Revoke permission [$($permission.Id)] was successful"
                                IsError = $false
                            })
                    } catch {
                        throw $_
                    }
                }
            } else {
                Write-Verbose 'No permissions to revoke'
                $auditLogs.Add([PSCustomObject]@{
                        Action  = 'RevokePermission'
                        Message = 'No permissions to revoke'
                        IsError = $false
                    })
            }
        }
    }

    # Process desired permissions to grant
    if ($desiredPermissions) {
        foreach ($permission in $desiredPermissions) {
            $outputContext.SubPermissions.Add([PSCustomObject]@{
                    DisplayName = $permission.Value
                    Reference   = [PSCustomObject]@{
                        Id = $permission.Name
                    }
                })

            if (-not $currentPermissions -or -not $currentPermissions.ContainsValue($permission.DisplayName)) {
                if (-Not($actionContext.DryRun -eq $true)) {
                    try {
                        $userIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        if (![string]::IsNullOrEmpty($correlatedAccount.ObjectGUID)) {
                            $userIdentity.IdentityType = 'guid'
                            $userIdentity.Value = $correlatedAccount.ObjectGUID
                        }

                        $resourceIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $resourceIdentity.IdentityType = 'guid'
                        $resourceIdentity.Value = $permission.Id
                        $ResourceAuthorization = [KPNBartConnectedServices.CommandService.ResourceAuthorizationEnum]::Access

                        Set-KPNBartResourceAccess -ResourceAuthorization $ResourceAuthorization -Identity $userIdentity -Add $true -ResourceIdentity $resourceIdentity

                        $outputContext.Success = $true
                        $outputContext.AuditLogs.Add([PSCustomObject]@{
                                Message = "Grant permission [$($permission.Id)] was successful"
                                IsError = $false
                            })
                    } catch {
                        throw $_
                    }
                }
            } else {
                Write-Verbose 'No permissions to grant'
                $auditLogs.Add([PSCustomObject]@{
                        Action  = 'GrantPermission'
                        Message = 'No permissions to grant'
                        IsError = $false
                    })
            }
        }
    }

    # Process permissions to update
    if ($actionContext.Operation -eq "update") {
        foreach ($permission in $newCurrentPermissions.GetEnumerator()) {
            if (-Not($actionContext.DryRun -eq $true)) {
                # Write permission update logic here
            }

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = "UpdatePermission"
                    Message = "Updated access to department share $($permission.Value)"
                    IsError = $false
                })
        }
    }

    $outputContext.Success = $true
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
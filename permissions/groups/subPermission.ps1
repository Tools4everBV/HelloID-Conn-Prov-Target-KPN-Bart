##########################################################################
# HelloID-Conn-Prov-Target-KPN-BART-GrantPermission-SubPermissionGroup
# PowerShell V2
##########################################################################

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
    $correlatedAccount = Get-KPNBartUser -Identity $queryObjectIdentity

    $currentPermissions = $correlatedAccount.Groups
    $contractsInScope = ($personContext.Contracts | Where-Object { $_.Context.InConditions -eq $true })
    if ($actionContext.dryRun -eq $true) {
        $contractsinScope = $personContext.Contracts
    }

    $desiredPermissions = [System.Collections.Generic.List[Object]]::new()
    $permissionsToGrant = [System.Collections.Generic.List[PSCustomObject]]::new()
    $permissionsToRevoke = [System.Collections.Generic.List[PSCustomObject]]::new()

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

    if ($desiredPermissions) {
        foreach ($permission in $desiredPermissions) {
            $subPermissions.Add([PSCustomObject]@{
                    DisplayName = $permission.displayName
                    Reference   = [PSCustomObject]@{
                        Id = $permission.id
                    }
                })

            if (-not $currentPermissions -or -not $currentPermissions.ContainsValue($permission.DisplayName)) {
                $permissionsToGrant.Add($permission)
            }
        }
    }

    if ($currentPermissions) {
        foreach ($permission in $currentPermissions) {
            if (-not $desiredPermissions.ContainsValue($permission.DisplayName)) {
                $permissionsToRevoke.Add($permission)
            } elseif (-not $desiredPermissions) {
                $permissionsToRevoke.Add($permission)
            }
        }
    }

    if ($null -ne $correlatedAccount) {
        $action = 'UpdatePermissions'
        $dryRunMessage = "Update KPN-BART permissions: [$($actionContext.References.Permission.DisplayName)] will be executed during enforcement"
    } else {
        $action = 'NotFound'
        $dryRunMessage = "KPN-BART account: [$($actionContext.References.Account.id)] for person: [$($personContext.Person.DisplayName)] could not be found, possibly indicating that it could be deleted, or the account is not correlated"
    }

    # Add a message and the result of each of the validations showing what will happen during enforcement
    if ($actionContext.DryRun -eq $true) {
        Write-Information "[DryRun] $dryRunMessage"

        if ($permissionsToGrant.count -gt 0) {
            Write-Information "[DryRun] Permissions to grant during enforcement $($desiredPermissions | ForEach-Object { $_.displayname } -join ', ')"
        }

        if ($permissionsToRevoke.count -gt 0) {
            Write-Information "[DryRun] Permissions to revoke during enforcement $($permissionsToRevoke | ForEach-Object { $_.displayname } -join ', ')"
        }
    }

    # Process
    if (-not($actionContext.DryRun -eq $true)) {
        switch ($action) {
            'UpdatePermissions' {
                if ($permissionToRevoke) {
                    # Remove permissions from the authorization
                    foreach ($permission in $permissionsToRevoke) {
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
                    Write-Verbose 'No permissions to revoke'
                    $auditLogs.Add([PSCustomObject]@{
                            Action  = 'RevokePermission'
                            Message = 'No permissions to revoke'
                            IsError = $false
                        })
                }

                if ($permissionsToGrant) {
                    # Add permissions to the authorization
                    foreach ($permission in $permissionsToGrant) {
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
                                    Message = "Revoke permission [$($permission.Id)] was successful"
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

            'NotFound' {
                $outputContext.Success = $false
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = "KPN-BART account: [$($actionContext.References.Account.id)] for person: [$($personContext.Person.DisplayName)] could not be found, possibly indicating that it could be deleted, or the account is not correlated"
                        IsError = $true
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
#################################################
# HelloID-Conn-Prov-Target-KPN-BART-Update
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

function Write-AuditLog {
    [CmdletBinding()]
    param (
        [parameter(Mandatory, Position = 0)]
        [string]
        $Message,

        [switch]
        $IsError
    )
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $Message
            IsError = $IsError
        })
}

try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account.Id))) {
        throw 'The account reference could not be found'
    }

    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    Import-Module $actionContext.Configuration.ModuleLocation -Force
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    Write-Information "Verifying if a KPN-BART account for [$($personContext.Person.DisplayName)] exists"
    $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
    $queryObjectIdentity.IdentityType = 'Guid'
    $queryObjectIdentity.Value = $actionContext.References.Account.Id
    $correlatedAccount = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes  ([string[]]($actionContext.Data.PSObject.Properties.name | Select-Object * -ExcludeProperty ExtensionData))
    $outputContext.PreviousData = $correlatedAccount

    Write-Information 'Define update actions'
    $actionList = [System.Collections.Generic.List[object]]::new()
    if ($null -ne $correlatedAccount) {
        $splatCompareProperties = @{
            ReferenceObject  = @($correlatedAccount.PSObject.Properties)
            DifferenceObject = @($actionContext.Data.PSObject.Properties | Select-Object * -ExcludeProperty ExtensionData)
        }
        # Always compare the account against the current account in target system
        $propertiesChanged = Compare-Object @splatCompareProperties -PassThru | Where-Object { $_.SideIndicator -eq '=>' }

        # Get previous manager
        try {
            $previousAccountManager = Get-KPNBartUserManager -Identity $queryObjectIdentity
        } catch {
            Write-AuditLog 'Manager not found was successful'
        }

        if ($propertiesChanged) {
            $actionList.Add('UpdateAccount')
            Write-Information "Account property(s) required to update: $($propertiesChanged.Name -join ', ')"
        }

        # Add extra condition to check if property already Disabled
        if (($actionContext.References.Account.accountCorrelated) -and ('True' -eq $correlatedAccount.IsActive)) {
            $actionList.Add('DisableAccount')
        }

        if (($actionContext.References.Account.accountCorrelated) -and ($actionContext.Data.ChangePasswordAtLogon)) {
            $actionList.Add('ChangePasswordAtLogon')
        }

        # Compare for userType
        if ($correlatedAccount.userType -ne $actionContext.Data.ExtensionData.UserType) {
            $actionList.Add('UpdateAccountType')
        }

        # Compare for manager
        if ($previousAccountManager.ObjectGuid -ne $actionContext.References.ManagerAccount) {
            $actionList.Add('UpdateManager')
        }

        # Compare for persona
        if ($correlatedAccount.persona -ne $actionContext.Data.ExtensionData.Persona) {
            $actionList.Add('SetPersona')
        }

        # Compare for email
        if ($correlatedAccount.mail -ne $actionContext.Data.ExtensionData.Mail) {
            $actionList.Add('AddEmailAliases')

            if ($actionContext.Data.ExtensionData.ExchangeWhenSettingMailAttribute -eq $false) {
                $actionList.Add('UpdateMailAD')
            } elseif ($actionContext.Data.ExtensionData.ExchangeWhenSettingMailAttribute) {
                $actionList.Add('UpdateMailEX')
            }
        }

        if ($actionList.Count -eq 0) {
            $actionList.Add('NoChanges')
        }
    } else {
        $actionList.Add('NotFound')
    }

    if ($actionContext.DryRun -eq $true) {
        Write-Information "Actions that will be executed during enforcement are: [$($actionList -join ', ')]"
    }

    # Process
    if (-not($actionContext.DryRun -eq $true)) {
        foreach ($action in $actionList) {
            try {
                switch ($action) {
                    'UpdateAccount' {
                        Write-Information "Updating KPN-BART account with accountReference: [$($actionContext.References.Account)]"

                        # Make sure to test with special characters and if needed; add utf8 encoding.
                        $bulkObjectIdentity = [KPNBartConnectedServices.BulkCommandService.ObjectIdentity]::new()
                        $bulkObjectIdentity.IdentityType = 'GUID'
                        $bulkObjectIdentity.Value = $actionContext.References.Account.Id

                        $commandList = [System.Collections.Generic.List[KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]]::New()
                        foreach ($prop in $propertiesChanged) {
                            $modifyCommand = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                            $modifyCommand.ObjectIdentity = $bulkObjectIdentity
                            $modifyCommand.Attribute = $prop.Name
                            $modifyCommand.Value = $prop.Value
                            $commandList.Add($modifyCommand)
                        }
                        $UpdateResults = Set-KPNBartUserAttributeMultiple -CommandList $CommandList
                        # Validate if this works :
                        foreach ($Result in $UpdateResults) {
                            if ($Result.error) {
                                Write-AuditLog  "user-create for person  $($p.DisplayName). Update of specific attribute failed with Error:  '$($Result.command.attribute)' to value '$($Result.command.value)'. Error: $($Result.Message)" -IsError
                            }
                        }

                        Write-AuditLog  "Update account was successful, Account property(s) updated: [$($propertiesChanged.name -join ',')]"
                        break
                    }

                    'ChangePasswordAtLogon' {
                        Write-Information "ChangePasswordAtLogon of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $null = Set-KPNBartPasswordChangeAtNextLogon  -Identity $commandObjectIdentity
                        Write-AuditLog  'Password was changed successful'
                        break
                    }

                    'DisableAccount' {
                        Write-Information "DisableAccount of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $null = Disable-KPNBartUser -Identity $commandObjectIdentity
                        Write-AuditLog 'DisableAccount was successful'
                        break
                    }

                    'UpdateMailAD' {
                        Write-Information "UpdateMailAD of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $null = Set-KPNBartEmailADAttribute -Identity $commandObjectIdentity -EmailAddress $actionContext.Data.Mail
                        Write-AuditLog 'UpdateMailAD was successful'
                        break
                    }

                    'UpdateMailEX' {
                        Write-Information "UpdateMailEX of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $null = Set-KPNBartEmailPrimaryAddress -Identity $commandObjectIdentity -EmailAddress $actionContext.Data.Mail
                        Write-AuditLog 'UpdateMailEX was successful'
                        break
                    }

                    'UpdateManager' {
                        Write-Information "UpdateManager of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $managerIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $managerIdentity.IdentityType = 'GUID'
                        $managerIdentity.Value = $actionContext.References.ManagerAccount

                        $null = Set-KPNBartUserManager -Identity $commandObjectIdentity -ManagerIdentity $managerIdentity
                        $outputContext.References.ManagerAccount = $managerIdentity.Value

                        Write-AuditLog 'SetManager was successful'
                        break
                    }

                    'SetPersona' {
                        Write-Information "SetPersona of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id


                        $null = Set-KPNBartUserPersona -Identity $commandObjectIdentity -Persona $actionContext.Data.Persona
                        Write-AuditLog 'SetPersona was successful'
                        break
                    }

                    'AddEmailAliases' {
                        Write-Information "AddEmailAliases of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        # Set aliases before setting primary
                        $null = New-KPNBartEmailAlias -Identity $commandObjectIdentity -EmailAddress $actionContext.Data.Mail
                        Write-AuditLog 'AddEmailAliases was successful'
                        break
                    }

                    'UpdateAccountType' {
                        Write-Information "UpdateAccountType of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $null = Set-KPNBartUserType  -Identity $commandObjectIdentity -userType $actionContext.Data.UserType
                        Write-AuditLog 'UpdateAccountType was successful'
                        break
                    }

                    'NoChanges' {
                        Write-Information "No changes to KPN-BART account with accountReference: [$($actionContext.References.Account)]"
                        Write-AuditLog  'No changes will be made to the account during enforcement'
                        break
                    }

                    'NotFound' {
                        Write-AuditLog "KPN-BART account with accountReference: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted, or the account is not correlated" -IsError
                        break
                    }
                }
            } catch {
                Write-Information "Could not $action KPN-Bart account. Error: $($errorObj.FriendlyMessage)"
                Write-AuditLog "Could not $action KPN-Bart account. Error: $($errorObj.FriendlyMessage)" -IsError
            }
        }
    }
    if (-not ($outputContext.AuditLogs.IsError -contains $true)) {
        $outputContext.success = $true

        if ($actionContext.AccountCorrelated) {
            # Check if remove AccountCreated is also a option
            $actionContext.References.Account.AccountCreated = $false
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
#################################################
# HelloID-Conn-Prov-Target-KPN-BART-Update
# PowerShell V2
#################################################
$debugBartFields = $false

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
            IsError = $IsError.IsPresent
        })
}

try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account.Id))) {
        throw 'The account reference could not be found'
    }

    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    $bartModule = Import-Module $actionContext.Configuration.ModuleLocation -Force -PassThru | Select-Object -First 1
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    Write-Information "Verifying if a KPN-BART account for [$($personContext.Person.DisplayName)] exists"
    $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
    $queryObjectIdentity.IdentityType = 'Guid'
    $queryObjectIdentity.Value = $actionContext.References.Account.Id
    $accountProperties = @($actionContext.Data.PSObject.Properties | Where-Object { $_.Name -ne 'ExtensionData' })
    $correlatedAccount = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes ([string[]]$accountProperties.Name)
    if ($correlatedAccount -is [System.Collections.IDictionary]) {
        $accountData = @{}
        foreach ($field in $correlatedAccount.Keys) {
            if ($field -isnot [string] -or [string]::IsNullOrWhiteSpace($field)) {
                throw 'The BART account response contains an invalid field name.'
            }
            $accountData[$field] = $correlatedAccount[$field]
        }
        $correlatedAccount = [pscustomobject]$accountData
    }

    $werkplekprofielProperty = $null
    if ($null -ne $actionContext.Data.ExtensionData) {
        $werkplekprofielProperty = $actionContext.Data.ExtensionData.PSObject.Properties['Werkplekprofiel']
    }

    # Debug: log BART attribute names and values; set to $false when no longer needed
   
    if ($debugBartFields) {
        $debugAttributeNames = [string[]]@(
            'ObjectGUID', 'SamAccountName', 'UserPrincipalName', 'DisplayName', 'mail',
            'employeeID', 'employeeNumber', 'employeeType', 'givenName', 'sn', 'initials', 'middleName',
            'title', 'department', 'company', 'telephoneNumber', 'mobile', 'otherMobile', 'userAccountControl'
        ) + @(1..15 | ForEach-Object { "extensionAttribute$_" }) + @($accountProperties.Name)
        $debugAttributeNames = [string[]]($debugAttributeNames | Select-Object -Unique)
        try {
            $debugAccount = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes $debugAttributeNames -ErrorAction Stop
            Write-Information "BART debug response type: [$($debugAccount.GetType().FullName)]"
            if ($debugAccount -is [System.Collections.IDictionary]) {
                foreach ($key in $debugAccount.Keys) {
                    Write-Information "BART field [$key] = [$($debugAccount[$key])]"
                }
            } else {
                foreach ($property in $debugAccount.PSObject.Properties) {
                    Write-Information "BART field [$($property.Name)] = [$($property.Value)]"
                }
            }
            Write-Information "HelloID fields to compare: $(($accountProperties | ForEach-Object { "[$($_.Name)]=[$($_.Value)]" }) -join ', ')"
        } catch {
            Write-Warning "BART debug query failed: $($_.Exception.Message). Inner: $($_.Exception.InnerException.Message). Retrying per attribute"
            foreach ($attributeName in $debugAttributeNames) {
                try {
                    $singleResult = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes ([string[]]@($attributeName)) -ErrorAction Stop
                    if ($singleResult -is [System.Collections.IDictionary]) {
                        $singleValue = $singleResult[$attributeName]
                    } else {
                        $singleValue = $singleResult.$attributeName
                    }
                    Write-Information "BART field [$attributeName] = [$singleValue]"
                } catch {
                    Write-Information "BART field [$attributeName] not available: $($_.Exception.Message)"
                }
            }
        }
    }

    $outputContext.PreviousData = $correlatedAccount

    # Create-only fields are not in the update mapping; add current BART values so they remain in account data
    if ($null -ne $correlatedAccount) {
        if ($null -eq $outputContext.Data) {
            $outputContext.Data = [pscustomobject]@{}
        }
        $storedAccountFields = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes ([string[]]@('SamAccountName', 'UserPrincipalName', 'mail')) -ErrorAction Stop
        foreach ($field in @('SamAccountName', 'UserPrincipalName')) {
            $outputContext.Data | Add-Member -NotePropertyName $field -NotePropertyValue $storedAccountFields.$field -Force
            $outputContext.PreviousData | Add-Member -NotePropertyName $field -NotePropertyValue $storedAccountFields.$field -Force
        }
        $mailAccountData = $storedAccountFields.mail
        if ($null -ne $actionContext.Data.ExtensionData -and $null -ne $actionContext.Data.ExtensionData.PSObject.Properties['Mail']) {
            $mailAccountData = $actionContext.Data.ExtensionData.Mail
        }
        if ($null -eq $outputContext.Data.ExtensionData) {
            $outputContext.Data | Add-Member -NotePropertyName 'ExtensionData' -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        $outputContext.Data.ExtensionData | Add-Member -NotePropertyName 'Mail' -NotePropertyValue $mailAccountData -Force
    }

    Write-Information 'Define update actions'
    $actionList = [System.Collections.Generic.List[object]]::new()
    if ($null -ne $correlatedAccount) {
        $splatCompareProperties = @{
            ReferenceObject  = @($correlatedAccount.PSObject.Properties | Where-Object { $_.Name -ne 'ExtensionData' })
            DifferenceObject = $accountProperties
            Property         = @('Name', 'Value')
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

        if ($null -ne $werkplekprofielProperty -and -not [string]::IsNullOrWhiteSpace([string]$werkplekprofielProperty.Value)) {
            $actionList.Add('UpdateWerkplekprofiel')
        }

        if (($actionContext.References.Account.accountCorrelated) -and ($actionContext.Data.ChangePasswordAtLogon)) {
            $actionList.Add('ChangePasswordAtLogon')
        }

        # Compare for userType
        if (-not [string]::IsNullOrWhiteSpace($actionContext.Data.ExtensionData.UserType) -and $correlatedAccount.userType -ne $actionContext.Data.ExtensionData.UserType) {
            if (-not [string]::IsNullOrWhiteSpace($actionContext.Data.ExtensionData.Persona)) {
                Write-Warning 'UserType conversion was skipped because a Persona is mapped. Configure the desired persona in ExtensionData.Persona instead of ExtensionData.UserType.'
            } else {
                $actionList.Add('UpdateAccountType')
            }
        }

        # Compare for manager
        $managerAccountReference = $actionContext.References.ManagerAccount
        if ($null -ne $managerAccountReference -and $null -ne $managerAccountReference.Id) {
            $managerAccountReference = $managerAccountReference.Id
        }
        $managerAccountId = [string]$managerAccountReference
        if (-not [string]::IsNullOrWhiteSpace($managerAccountId)) {
            $managerGuid = [guid]::Empty
            if (-not [guid]::TryParse($managerAccountId, [ref]$managerGuid) -or $managerGuid -eq [guid]::Empty) {
                throw 'The manager account reference does not contain a valid BART ObjectGUID. Check References.ManagerAccount.Id and the manager account correlation.'
            }
            $managerAccountId = $managerGuid.ToString()
            if ($previousAccountManager.ObjectGuid -ne $managerAccountId) {
                $actionList.Add('UpdateManager')
            }
        }

        # Compare for persona: BART has no per-user persona query, so check if the user is in the list of users with the desired persona
        if ($null -ne $actionContext.Data.ExtensionData -and $null -ne $actionContext.Data.ExtensionData.PSObject.Properties['Persona'] -and -not [string]::IsNullOrEmpty($actionContext.Data.ExtensionData.Persona)) {
            $desiredPersona = [string]$actionContext.Data.ExtensionData.Persona
            $hasDesiredPersona = $false
            $personaExists = $true
            try {
                # BART persona names are case-sensitive in queries; resolve the exact BART name
                $availablePersonas = @(Get-KPNBartPersona -ErrorAction Stop | ForEach-Object { $_ } | Where-Object { $null -ne $_.Name })
                $matchedPersona = $availablePersonas | Where-Object { $_.Name.Trim() -eq $desiredPersona.Trim() } | Select-Object -First 1
                if ($null -eq $matchedPersona) {
                    $personaExists = $false
                    throw "Persona [$desiredPersona] does not exist in BART. Available personas: [$(($availablePersonas | ForEach-Object { $_.Name }) -join ', ')]"
                }
                $desiredPersona = $matchedPersona.Name
                $resolvedPersona = $desiredPersona

                $personaResponse = Get-KPNBartUser -Persona $desiredPersona -ErrorAction Stop
                if ($debugBartFields) {
                    if ($null -eq $personaResponse) {
                        Write-Information "Persona query for [$desiredPersona] returned no response"
                    } else {
                        Write-Information "Persona query response type: [$($personaResponse.GetType().FullName)]"
                    }
                }

                # Response structure is unknown, so collect every string value at any depth
                $personaValues = [System.Collections.Generic.List[string]]::new()
                $stack = [System.Collections.Generic.Stack[object]]::new()
                $stack.Push(@($personaResponse, 0))
                while ($stack.Count -gt 0) {
                    $entry = $stack.Pop()
                    $node = $entry[0]
                    $depth = $entry[1]
                    if ($null -eq $node) { continue }
                    if ($node -is [string] -or $node -is [guid] -or $node.GetType().IsPrimitive) {
                        $personaValues.Add([string]$node)
                    } elseif ($depth -ge 5) {
                        continue
                    } elseif ($node -is [System.Collections.IDictionary]) {
                        foreach ($key in $node.Keys) {
                            $stack.Push(@($key, ($depth + 1)))
                            $stack.Push(@($node[$key], ($depth + 1)))
                        }
                    } elseif ($node -is [System.Collections.IEnumerable]) {
                        foreach ($child in $node) { $stack.Push(@($child, ($depth + 1))) }
                    } else {
                        foreach ($property in $node.PSObject.Properties) {
                            if ($property.Name -ne 'ExtensionData') { $stack.Push(@($property.Value, ($depth + 1))) }
                        }
                    }
                }
                if ($debugBartFields) {
                    Write-Information "Persona query values found: [$($personaValues.Count)]. Sample: [$(($personaValues | Select-Object -First 5) -join ', ')]"
                }

                $identifierAccount = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes ([string[]]@('SamAccountName', 'UserPrincipalName', 'distinguishedName')) -ErrorAction Stop
                $accountIdentifiers = @([string]$actionContext.References.Account.Id, [string]$identifierAccount['SamAccountName'], [string]$identifierAccount['UserPrincipalName'], [string]$identifierAccount['distinguishedName']) | Where-Object { -not [string]::IsNullOrEmpty($_) }
                $hasDesiredPersona = @($personaValues | Where-Object { $_ -in $accountIdentifiers }).Count -gt 0
                if ($debugBartFields) {
                    Write-Information "Account has persona [$desiredPersona]: [$hasDesiredPersona]"
                }
            } catch {
                if (-not $personaExists) {
                    Write-AuditLog $_.Exception.Message -IsError
                    $hasDesiredPersona = $true
                } else {
                    Write-Warning "Could not determine current persona, persona will be set. Error: $($_.Exception.Message)"
                }
            }
            if (-not $hasDesiredPersona) {
                $actionList.Add('SetPersona')
            }
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
                            # Department is a selection list in BART; the value must exist there first
                            if ($prop.Name -eq 'Department' -and -not [string]::IsNullOrEmpty([string]$prop.Value)) {
                                $departmentResponse = & $bartModule { param($q) $script:QueryService.Execute($q) } ([KPNBartConnectedServices.QueryService.DepartmentQuery]::new())
                                $bartDepartments = @(foreach ($item in @($departmentResponse)) {
                                        if ($item -is [string]) { $item }
                                        elseif ($null -ne $item.Name) { [string]$item.Name }
                                        elseif ($null -ne $item) { [string]$item }
                                    })
                                Write-Information "BART departments: [$($bartDepartments -join ', ')]"

                                if ($prop.Value -notin $bartDepartments) {
                                    Write-AuditLog "Department [$($prop.Value)] does not exist in BART and was not updated. Please create this department in BART first."
                                    continue
                                }
                            }

                            $modifyCommand = [KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]::new()
                            $modifyCommand.ObjectIdentity = $bulkObjectIdentity
                            $modifyCommand.Attribute = $prop.Name
                            $modifyCommand.Value = $prop.Value
                            $commandList.Add($modifyCommand)
                        }
                        if ($commandList.Count -eq 0) {
                            break
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

                    'UpdateWerkplekprofiel' {
                        Write-Information "Updating Werkplekprofiel of KPN-BART account with accountReference: [$($actionContext.References.Account)]"
                        $desktopQuery = [KPNBartConnectedServices.QueryService.DesktopQuery]::new()
                        $availableDesktops = & $bartModule { param($query) $script:QueryService.Execute($query) } $desktopQuery
                        Write-Information "Available KPN-BART desktops: $(ConvertTo-Json -InputObject @($availableDesktops) -Depth 10 -Compress)"

                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $setDesktopsCommand = [KPNBartConnectedServices.CommandService.SetDesktopsCommand]::new()
                        $setDesktopsCommand.ObjectIdentity = $commandObjectIdentity
                        $setDesktopsCommand.Desktops = [string[]]@([string]$werkplekprofielProperty.Value)
                        $null = & $bartModule { param($command) $script:CommandService.Execute($command) } $setDesktopsCommand
                        Write-AuditLog "Werkplekprofiel update command was sent to BART with value [$($werkplekprofielProperty.Value)]"
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

                        $null = Set-KPNBartEmailADAttribute -Identity $commandObjectIdentity -EmailAddress $actionContext.Data.ExtensionData.Mail
                        Write-AuditLog 'UpdateMailAD was successful'
                        break
                    }

                    'UpdateMailEX' {
                        Write-Information "UpdateMailEX of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $null = Set-KPNBartEmailPrimaryAddress -Identity $commandObjectIdentity -EmailAddress $actionContext.Data.ExtensionData.Mail
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
                        $managerIdentity.Value = $managerAccountId

                        $null = Set-KPNBartUserManager -Identity $commandObjectIdentity -ManagerIdentity $managerIdentity -ErrorAction Stop

                        Write-AuditLog 'SetManager was successful'
                        break
                    }

                    'SetPersona' {
                        Write-Information "SetPersona of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id


                        $personaToSet = $actionContext.Data.ExtensionData.Persona
                        if (-not [string]::IsNullOrEmpty($resolvedPersona)) {
                            $personaToSet = $resolvedPersona
                        }
                        $null = Set-KPNBartUserPersona -Identity $commandObjectIdentity -Persona $personaToSet
                        Write-AuditLog "SetPersona [$personaToSet] was successful"
                        break
                    }

                    'AddEmailAliases' {
                        Write-Information "AddEmailAliases of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        # Set aliases before setting primary
                        $null = New-KPNBartEmailAlias -Identity $commandObjectIdentity -EmailAddress $actionContext.Data.ExtensionData.Mail
                        Write-AuditLog 'AddEmailAliases was successful'
                        break
                    }

                    'UpdateAccountType' {
                        Write-Information "UpdateAccountType of KPN-Bart account with accountReference: [$($actionContext.References.Account)]"
                        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                        $commandObjectIdentity.IdentityType = 'GUID'
                        $commandObjectIdentity.Value = $actionContext.References.Account.Id

                        $null = Set-KPNBartUserType -Identity $commandObjectIdentity -UserType $actionContext.Data.ExtensionData.UserType -ErrorAction Stop
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
                $actionError = $_.Exception.Message
                if ($null -ne $_.Exception.InnerException) {
                    $actionError = "$actionError. Inner error: $($_.Exception.InnerException.Message)"
                }
                Write-Warning "Error at Line '$($_.InvocationInfo.ScriptLineNumber)': $($_.InvocationInfo.Line). Error: $actionError"
                Write-AuditLog "Could not $action KPN-Bart account. Error: $actionError" -IsError
            }
        }
    }
} catch {
    $outputContext.success = $false
    $ex = $PSItem

    $auditMessage = "Could not create or correlate KPN-Bart account. Error: $($ex.Exception.Message)"
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"

    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
} finally {
    $outputContext.Success = -not ($outputContext.AuditLogs.IsError -contains $true)

    if ($outputContext.Success -and $actionContext.AccountCorrelated) {
        # Check if remove AccountCreated is also a option
        $actionContext.References.Account.AccountCreated = $false
    }
}
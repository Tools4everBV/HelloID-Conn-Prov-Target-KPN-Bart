#################################################
# HelloID-Conn-Prov-Target-KPN-Bart-Create
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

function ConvertTo-BartAccountData {
    param ($Account)

    if ($null -eq $Account -or $Account -is [bool]) {
        throw 'No account was returned by BART. Verify the existing account before retrying creation.'
    }

    Write-Information "BART account response type: [$($Account.GetType().FullName)]"
    $accountData = @{}
    if ($Account -is [System.Collections.IDictionary]) {
        foreach ($field in $Account.Keys) {
            if ($field -isnot [string] -or [string]::IsNullOrWhiteSpace($field)) {
                throw 'The BART account response contains an invalid field name.'
            }
            if ($field -notin @('Password', 'ExtensionData')) {
                $accountData[$field] = $Account[$field]
            }
        }
    } elseif ($Account -is [pscustomobject]) {
        foreach ($property in $Account.PSObject.Properties) {
            if ([string]::IsNullOrWhiteSpace($property.Name)) {
                throw 'The BART account response contains an invalid field name.'
            }
            if ($property.Name -notin @('Password', 'ExtensionData')) {
                $accountData[$property.Name] = $property.Value
            }
        }
    } else {
        throw 'BART returned an unsupported account response type. Check the reported response type and module version.'
    }

    $knownFields = @('ObjectGUID') + @($actionContext.Data.PSObject.Properties.Name)
    $reportedFields = @($accountData.Keys | Where-Object { $_ -in $knownFields } | Sort-Object)
    Write-Information "BART account response recognized fields: [$($reportedFields -join ', ')]"
    $accountGuid = [guid]::Empty
    if (-not [guid]::TryParse([string]$accountData['ObjectGUID'], [ref]$accountGuid) -or $accountGuid -eq [guid]::Empty) {
        throw 'BART did not return a valid ObjectGUID. Verify the existing account before retrying creation.'
    }
    $accountData['ObjectGUID'] = $accountGuid.ToString()
    return [pscustomobject]$accountData
}

try {
    $action = 'CreateAccount'
    # Initial Assignments
    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    Import-Module $actionContext.Configuration.ModuleLocation -Force
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    # Validate correlation configuration
    $correlationEnabled = $actionContext.CorrelationConfiguration.Enabled -eq $true
    Write-Information "KPN-BART correlation enabled: [$correlationEnabled]"
    if ($correlationEnabled) {
        $correlationField = $actionContext.CorrelationConfiguration.accountField
        $correlationValue = $actionContext.CorrelationConfiguration.accountFieldValue

        if ([string]::IsNullOrWhiteSpace([string]$correlationField)) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrWhiteSpace([string]$correlationValue)) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        $ObjectAttributes = [string[]]@('ObjectGUID', $correlationField)
        $userList = Get-KPNBartUser -Attributes $objectAttributes -ErrorAction Stop
        if ($null -eq $userList) {
            throw 'BART returned no correlation query response. Account creation was stopped to avoid duplicates.'
        }
        Write-Information "BART correlation response type: [$($userList.GetType().FullName)]"
        if ($userList -is [System.Collections.IDictionary]) {
            $candidates = @($userList.Values)
        } elseif ($userList -is [array]) {
            $candidates = @($userList)
        } else {
            throw 'BART returned an unsupported correlation query response. Account creation was stopped to avoid duplicates.'
        }

        $correlatedAccount = [System.Collections.Generic.List[object]]::new()
        $fieldPresentCount = 0
        foreach ($candidate in $candidates) {
            $candidateFields = @{}
            if ($candidate -is [System.Collections.IDictionary]) {
                foreach ($field in $candidate.Keys) {
                    if ($field -isnot [string] -or [string]::IsNullOrWhiteSpace($field) -or $candidateFields.ContainsKey($field)) {
                        throw 'BART returned invalid or ambiguous correlation field names. Account creation was stopped.'
                    }
                    $candidateFields[$field] = $candidate[$field]
                }
            } elseif ($candidate -is [pscustomobject]) {
                foreach ($property in $candidate.PSObject.Properties) {
                    $candidateFields[$property.Name] = $property.Value
                }
            } else {
                throw 'BART returned an unsupported correlation account record. Account creation was stopped.'
            }
            if ($candidateFields.ContainsKey([string]$correlationField)) {
                $fieldPresentCount++
                if ($candidateFields[[string]$correlationField] -eq $correlationValue) {
                    $correlatedAccount.Add([pscustomobject]$candidateFields)
                }
            }
        }
        Write-Information "BART correlation records: [$($candidates.Count)], records with configured field: [$fieldPresentCount], matches: [$($correlatedAccount.Count)]"
        if ($candidates.Count -gt 0 -and $fieldPresentCount -eq 0) {
            throw 'The configured correlation field is absent from all BART account records. Check the account field configuration and query support before creating accounts.'
        }

        if ($correlatedAccount.Count -gt 1) {
            throw  'More than one account found. Please find the accounts in BART and remove the employeeID from the unmanaged account.'
        } elseif ($correlatedAccount.Count -eq 1) {
            $action = 'CorrelateAccount'
            $correlatedAccount = $correlatedAccount | Select-Object -First 1
            $correlatedGuid = [guid]::Empty
            if (-not [guid]::TryParse([string]$correlatedAccount.ObjectGUID, [ref]$correlatedGuid) -or $correlatedGuid -eq [guid]::Empty) {
                throw 'The matched BART account has no valid ObjectGUID. Account creation was stopped.'
            }
            $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
            $queryObjectIdentity.IdentityType = 'Guid'
            $queryObjectIdentity.Value = $correlatedAccount.ObjectGUID
            [string[]]$ObjectAttributes = @('ObjectGUID') + @($actionContext.Data.PSObject.Properties.Name | Where-Object { $_ -notin @('Password', 'ExtensionData') })
            $correlatedAccount = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes $objectAttributes -ErrorAction Stop
        } else {
            $action = 'CreateAccount'
        }
    }

    # Add a message and the result of each of the validations showing what will happen during enforcement
    if ($actionContext.DryRun -eq $true) {
        if ($action -eq 'CreateAccount') {
            $outputContext.AccountReference = 'Currently not available'
        }
        Write-Information "[DryRun] $action KPN-Bart account for: [$($personContext.Person.DisplayName)], will be executed during enforcement"
    }

    # Process
    if (-not($actionContext.DryRun -eq $true)) {
        switch ($action) {
            'CreateAccount' {
                Write-Information 'Creating and correlating KPN-Bart account'
                # Possible properties by the web service for the CreateUserCommand
                $accountCreateAttributes = @('FirstName', 'LastName', 'Initials', 'Password', 'UserPrincipalName', 'DisplayName', 'MiddleName', 'SamAccountName')

                $splatAccountCreate = @{}
                $actionContext.Data.Password = ConvertTo-SecureString $actionContext.Data.Password -Force -AsPlainText
                foreach ($key in $actionContext.Data.PSObject.Properties) {
                    if ($accountCreateAttributes.Contains($key.Name)) {
                        $splatAccountCreate.Add($key.Name, $key.Value)
                    }
                }

                # New-KPNBartUser  change output to write-output from null
                if ([string]::IsNullOrWhiteSpace($splatAccountCreate.UserPrincipalName)) {
                    throw 'UserPrincipalName is required to retrieve the account after creation. Check the field mapping.'
                }
                $null = New-KPNBartUser @splatAccountCreate -ErrorAction Stop
                $splat = @{
                    attribute = 'UserPrincipalName'
                    value     = $splatAccountCreate.UserPrincipalName
                }
                $createdAccount = Get-BartUserByIdentityType @splat -ErrorAction Stop
                $createdAccount = ConvertTo-BartAccountData -Account $createdAccount
                $outputContext.Data = $createdAccount
                $outputContext.AccountCorrelated = $true
                $outputContext.AccountReference = @{
                    Id             = $createdAccount.ObjectGUID
                    AccountCreated = $true
                }

                # New accounts must stay disabled; enabling is only done by enable.ps1
                Write-Information "Disabling newly created KPN-Bart account [$($createdAccount.ObjectGUID)]"
                $disableObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                $disableObjectIdentity.IdentityType = 'Guid'
                $disableObjectIdentity.Value = $createdAccount.ObjectGUID
                try {
                    $null = Disable-KPNBartUser -Identity $disableObjectIdentity -ErrorAction Stop
                } catch {
                    throw "Account [$($createdAccount.ObjectGUID)] was created but could not be disabled. Error: $($_.Exception.Message) $($_.Exception.InnerException.Message)"
                }

                $auditLogMessage = 'Create account was successful, the account is disabled and a valid account reference was returned.'
                break
            }

            'CorrelateAccount' {
                Write-Information 'Correlating KPN-Bart account'

                $correlatedAccount = ConvertTo-BartAccountData -Account $correlatedAccount
                $outputContext.Data = $correlatedAccount
                $outputContext.AccountReference = @{
                    Id             = $correlatedAccount.ObjectGUID
                    AccountCreated = $false
                }
                $outputContext.AccountCorrelated = $true
                $auditLogMessage = 'An existing account was correlated and a valid account reference was returned.'
                break
            }
        }

        $outputContext.success = $true
        $outputContext.AuditLogs.Add([PSCustomObject]@{
                Action  = $action
                Message = $auditLogMessage
                IsError = $false
            })
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
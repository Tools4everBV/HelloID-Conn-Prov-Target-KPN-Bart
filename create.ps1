#################################################
# HelloID-Conn-Prov-Target-KPN-Bart-Create
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

try {
    # Initial Assignments
    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    Import-Module $actionContext.Configuration.ModuleLocation -Force
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    # Validate correlation configuration
    if ($actionContext.CorrelationConfiguration.Enabled) {
        $correlationField = $actionContext.CorrelationConfiguration.accountField
        $correlationValue = $actionContext.CorrelationConfiguration.accountFieldValue

        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        # TODO: Check if all attributes can be fetched which [KPNBartConnectedServices.QueryService.UsersMultipleAttributeQuery]::new()
        # (Only necessary when the SearchFilter works with EmployeeID)

        $ObjectAttributes = [string[]]@('ObjectGUID', $correlationField)
        $userList = Get-KPNBartUser -Attributes $objectAttributes
        $correlatedAccount = ($userList.Values.where({ $_.Keys -eq $attribute -and $_.Values -eq $correlationValue }))

        if (($correlatedAccount | Measure-Object ).count -gt 1) {
            throw  'More than one account found. Please find the accounts in BART and remove the employeeID from the unmanaged account.'
        } elseif (($correlatedAccount | Measure-Object ).count -eq 1) {
            $action = 'CorrelateAccount'
            $correlatedAccount = $correlatedAccount | Select-Object -First 1
            $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
            $queryObjectIdentity.IdentityType = 'Guid'
            $queryObjectIdentity.Value = $correlatedAccount.ObjectGUID
            [string[]]$ObjectAttributes = ([string[]]($actionContext.Data.PSObject.Properties | Select-Object * -ExcludeProperty ExtensionData).name)
            $correlatedAccount = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes $objectAttributes
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
                $null = New-KPNBartUser @splatAccountCreate
                $splat = @{
                    attribute = 'UserPrincipalName'
                    value     = $splatAccountCreate.UserPrincipalName
                }
                # Leave the account in Enabled State, disable will be performed in Update.ps1
                $createdAccount = Get-BartUserByIdentityType @splat
                $outputContext.Data = $createdAccount
                $outputContext.AccountCorrelated = $true
                $outputContext.AccountReference = @{
                    Id             = $createdAccount.ObjectGUID
                    AccountCreated = $true
                }
                $auditLogMessage = "Create account was successful. AccountReference is: [$($outputContext.AccountReference)"
                break
            }

            'CorrelateAccount' {
                Write-Information 'Correlating KPN-Bart account'

                $outputContext.Data = $correlatedAccount
                $outputContext.AccountReference = @{
                    Id             = $correlatedAccount.ObjectGUID
                    AccountCreated = $false
                }
                $outputContext.AccountCorrelated = $true
                $auditLogMessage = "Correlated account: [$($correlatedAccount.ExternalId)] on field: [$($correlationField)] with value: [$($correlationValue)]"
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
#################################################
# HelloID-Conn-Prov-Target-KPN-BART-Enable
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

try {
    $actionMessage = 'validating account reference'
    if ([string]::IsNullOrEmpty([string]$actionContext.References.Account.Id)) {
        throw 'The account reference could not be found'
    }
    $accountId = [string]$actionContext.References.Account.Id

    $actionMessage = 'initializing KPN-Bart service clients'
    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    Import-Module $actionContext.Configuration.ModuleLocation -Force
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    $actionMessage = 'verifying if account exists'
    Write-Information "Verifying if KPN-BART account [$accountId] for [$($personContext.Person.DisplayName)] exists"
    $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
    $queryObjectIdentity.IdentityType = 'Guid'
    $queryObjectIdentity.Value = $accountId

    $accountExists = $true
    $isActive = $null
    try {
        $activeResponse = Get-KPNBartUserIsActive -Identity $queryObjectIdentity -ErrorAction Stop
        if ($null -eq $activeResponse) {
            $accountExists = $false
        } elseif ($activeResponse -is [bool]) {
            $isActive = $activeResponse
        } elseif ($null -ne $activeResponse.IsActive) {
            $isActive = 'True' -eq [string]$activeResponse.IsActive
        }
    } catch {
        if ("$($_.Exception.Message) $($_.Exception.InnerException.Message)" -match 'not found|does not exist|niet gevonden|bestaat niet') {
            $accountExists = $false
        } else {
            throw
        }
    }
    Write-Information "Account exists: [$accountExists]. Active: [$isActive]"

    if (-not $accountExists) {
        $action = 'NotFound'
        $dryRunMessage = "KPN-BART account [$accountId] for person [$($personContext.Person.DisplayName)] could not be found, possibly indicating that it could be deleted, or the account is not correlated"
    } elseif ($true -eq $isActive) {
        $action = 'NoChanges'
        $dryRunMessage = "KPN-BART account [$accountId] for person [$($personContext.Person.DisplayName)] is already enabled"
    } else {
        $action = 'EnableAccount'
        $dryRunMessage = "Enable KPN-BART account [$accountId] for person [$($personContext.Person.DisplayName)] will be executed during enforcement"
    }

    if ($actionContext.DryRun -eq $true) {
        Write-Information "[DryRun] $dryRunMessage"
        $outputContext.Success = $true
    }

    # Process
    if (-not($actionContext.DryRun -eq $true)) {
        switch ($action) {
            'EnableAccount' {
                $actionMessage = 'enabling account'
                Write-Information "Enabling KPN-BART account [$accountId]"

                $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                $commandObjectIdentity.IdentityType = 'Guid'
                $commandObjectIdentity.Value = $accountId
                $null = Enable-KPNBartUser -Identity $commandObjectIdentity -ErrorAction Stop

                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = 'Enable account was successful'
                        IsError = $false
                    })
                break
            }

            'NoChanges' {
                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = $dryRunMessage
                        IsError = $false
                    })
                break
            }

            'NotFound' {
                $outputContext.Success = $false
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = $dryRunMessage
                        IsError = $true
                    })
                break
            }
        }
    }
} catch {
    $outputContext.Success = $false
    $ex = $PSItem
    $errorMessage = $ex.Exception.Message
    if ($null -ne $ex.Exception.InnerException) {
        $errorMessage = "$errorMessage. Inner error: $($ex.Exception.InnerException.Message)"
    }
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $errorMessage"

    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = "Could not enable KPN-Bart account. Error $($actionMessage): $errorMessage"
            IsError = $true
        })
}
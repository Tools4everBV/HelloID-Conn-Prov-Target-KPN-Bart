##################################################
# HelloID-Conn-Prov-Target-KPN-BART-Delete
# PowerShell V2
##################################################

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
    try {
        $activeResponse = Get-KPNBartUserIsActive -Identity $queryObjectIdentity -ErrorAction Stop
        if ($null -eq $activeResponse) {
            $accountExists = $false
        }
    } catch {
        if ("$($_.Exception.Message) $($_.Exception.InnerException.Message)" -match 'not found|does not exist|niet gevonden|bestaat niet') {
            $accountExists = $false
        } else {
            throw
        }
    }
    Write-Information "Account exists: [$accountExists]"

    if ($accountExists) {
        $action = 'DeleteAccount'
        $dryRunMessage = "Delete KPN-BART account [$accountId] for person [$($personContext.Person.DisplayName)] will be executed during enforcement"
    } else {
        $action = 'NotFound'
        $dryRunMessage = "KPN-BART account [$accountId] for person [$($personContext.Person.DisplayName)] could not be found, possibly indicating that it is already deleted, or the account is not correlated"
    }

    if ($actionContext.DryRun -eq $true) {
        Write-Information "[DryRun] $dryRunMessage"
        $outputContext.Success = $true
    }

    # Process
    if (-not($actionContext.DryRun -eq $true)) {
        switch ($action) {
            'DeleteAccount' {
                $actionMessage = 'deleting account'
                Write-Information "Deleting KPN-BART account [$accountId]"

                $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                $commandObjectIdentity.IdentityType = 'Guid'
                $commandObjectIdentity.Value = $accountId
                $null = Remove-KPNBartUser -Identity $commandObjectIdentity -ErrorAction Stop

                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = 'Delete account was successful'
                        IsError = $false
                    })
                break
            }

            'NotFound' {
                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = $dryRunMessage
                        IsError = $false
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
            Message = "Could not delete KPN-Bart account. Error $($actionMessage): $errorMessage"
            IsError = $true
        })
}
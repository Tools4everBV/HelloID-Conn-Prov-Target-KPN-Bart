#################################################
# HelloID-Conn-Prov-Target-KPN-Bart-Import
# Correlate to account
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function ConvertTo-BartAccountObject {
    param ($Account)

    $accountData = [ordered]@{}
    if ($Account -is [System.Collections.IDictionary]) {
        foreach ($field in $Account.Keys) {
            $accountData[[string]$field] = $Account[$field]
        }
    } elseif ($null -ne $Account) {
        foreach ($property in $Account.PSObject.Properties) {
            $accountData[$property.Name] = $property.Value
        }
    }
    return [pscustomobject]$accountData
}
#endregion functions

try {
    Write-Information 'Starting target account import'

    # Define properties to query (ExtensionData and Password are not AD attributes)
    $importFields = @($actionContext.ImportFields | ForEach-Object { $_ -replace '\..*', '' } | Where-Object { $_ -notin @('ExtensionData', 'Password') })

    # Add mandatory fields for HelloID to query and return
    foreach ($mandatoryField in @('ObjectGUID', 'DisplayName', 'UserPrincipalName', 'SamAccountName', 'userAccountControl')) {
        if ($mandatoryField -notin $importFields) { $importFields += $mandatoryField }
    }
    [string[]]$objectAttributes = $importFields | Select-Object -Unique
    Write-Information "Querying fields [$($objectAttributes -join ',')]"

    $actionMessage = 'initializing KPN-Bart service clients'
    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    Import-Module $actionContext.Configuration.ModuleLocation -Force
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    #region Get accounts
    $actionMessage = 'querying accounts'
    $userList = Get-KPNBartUser -Attributes $objectAttributes -ErrorAction Stop

    if ($userList -is [System.Collections.IDictionary]) {
        $existingAccounts = @($userList.Values)
    } else {
        $existingAccounts = @($userList | Where-Object { $null -ne $_ })
    }
    Write-Information "Queried users. Result count: $(($existingAccounts | Measure-Object).Count)"
    #endregion Get accounts

    # Map the imported data to the account field mappings
    $actionMessage = 'mapping accounts'
    foreach ($rawAccount in $existingAccounts) {
        $account = ConvertTo-BartAccountObject -Account $rawAccount

        $accountGuid = [guid]::Empty
        if (-not [guid]::TryParse([string]$account.ObjectGUID, [ref]$accountGuid) -or $accountGuid -eq [guid]::Empty) {
            Write-Warning "Skipping account without valid ObjectGUID. DisplayName: [$($account.DisplayName)]"
            continue
        }
        $account.ObjectGUID = $accountGuid.ToString()

        # Determine enabled state: ACCOUNTDISABLE flag (0x2) in userAccountControl, fallback to IsUserActive query
        $enabled = $null
        $uac = 0
        if ([int]::TryParse([string]$account.userAccountControl, [ref]$uac)) {
            $enabled = -not [bool]($uac -band 2)
        } else {
            $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
            $queryObjectIdentity.IdentityType = 'Guid'
            $queryObjectIdentity.Value = $account.ObjectGUID
            $isActiveResponse = Get-KPNBartUserIsActive -Identity $queryObjectIdentity -ErrorAction Stop
            $enabled = 'True' -eq [string]$isActiveResponse
        }

        # Make sure the DisplayName has a value
        $displayName = $account.DisplayName
        if ([string]::IsNullOrEmpty($displayName)) {
            $displayName = $account.ObjectGUID
        }
        # Make sure the Username has a value
        $userName = $account.UserPrincipalName
        if ([string]::IsNullOrEmpty($userName)) {
            $userName = $account.SamAccountName
        }
        if ([string]::IsNullOrEmpty($userName)) {
            $userName = $account.ObjectGUID
        }

        # Return the result
        Write-Output @{
            AccountReference = @{
                Id             = $account.ObjectGUID
                AccountCreated = $false
            }
            DisplayName      = $displayName
            UserName         = $userName
            Enabled          = $enabled
            Data             = $account
        }
    }

    Write-Information 'Target account import completed'
} catch {
    $ex = $PSItem
    $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    if ($null -ne $ex.Exception.InnerException) {
        $warningMessage = "$warningMessage. Inner error: $($ex.Exception.InnerException.Message)"
    }

    Write-Warning $warningMessage

    # Required to write an error as uniqueness check doesn't show auditlog
    Write-Error $auditMessage
}

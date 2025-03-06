############################################################
# HelloID-Conn-Prov-Target-KPN-BART-Permissions-Group
# PowerShell V2
############################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

try {
    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    Import-Module $actionContext.Configuration.ModuleLocation -Force
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    Write-Information 'Retrieving permissions'
    $resultGroupList = Get-KPNBartResource -ResourceType Group
    $groups = $resultGroupList.ResourceModel

    $permissions = $groups | Select-Object   @{Name = 'DisplayName';    Expression = { "Group_$($_.DisplayName)" } } ,
    @{Name = 'Identification'; Expression = { @{ Reference = $_.ObjectGuid } } }

    # Make sure to test with special characters and if needed; add utf8 encoding.
    foreach ($permission in $permissions) {
        $outputContext.Permissions.Add(
            @{
                DisplayName    = $permission.DisplayName
                Identification = @{
                    Reference   = $permission.Identification
                    DisplayName = $permission.DisplayName
                }
            }
        )
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

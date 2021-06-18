function New-WSHttpBinding {
    <#
    .SYNOPSIS
    Creates a new wsHttp binding

    .DESCRIPTION
    Creates a new wsHttp binding. The wsHttpBinding that support the SOAP protocol
    #>
    [OutputType([System.ServiceModel.WSHttpBinding])]
    [CmdletBinding()]
    param (
    )

    $binding = [System.ServiceModel.WSHttpBinding]::new([System.ServiceModel.SecurityMode]::Transport)
    $binding.Security.Transport.ClientCredentialType = [System.ServiceModel.HttpClientCredentialType]::Windows
    $binding.MessageEncoding = [System.ServiceModel.WSMessageEncoding]::Text
    $binding.TextEncoding = [System.Text.Encoding]::UTF8

    $fiveMinutes = [timespan]::new(0, 5, 0)
    $tenMinutes = [timespan]::new(0, 10, 0)
    $sixtyMinutes = [timespan]::new(1, 0, 0)

    $binding.SendTimeout = $tenMinutes
    $binding.ReceiveTimeout = $sixtyMinutes
    $binding.CloseTimeout = $fiveMinutes
    $binding.OpenTimeout = $fiveMinutes

    Write-Output $binding
}
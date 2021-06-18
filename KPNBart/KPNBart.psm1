if ($MyInvocation.line -match "-verbose"){
    $VerbosePreference = "Continue"
}

try {
    Write-Verbose "Loading external functions"

    $public = @( Get-ChildItem -Recurse -Path $PSScriptRoot\public\*.ps1 -ErrorAction Stop )
    $private = @( Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction Stop )
    foreach($psFile in @($public + $private)) {
        . $psFile.FullName
    }
} catch {
    throw $_
}

Export-ModuleMember -Function $public.Basename
Export-ModuleMember -Function $private.BaseName
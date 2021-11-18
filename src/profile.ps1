# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.
<#if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity
}#>

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.

# Import library
Get-ChildItem -Path "$PSScriptRoot\lib" -Filter "*.psm1" | Foreach-Object {
    Write-Host "Importing $($_.Name)"
    Import-Module $_.FullName -Force -DisableNameChecking
}

if ($env:AUTH_CERTIFICATE_FILE) {
    $authCert = Prepare-Certificate -FilePath $env:AUTH_CERTIFICATE_FILE
}
elseif ($env:AUTH_KEYVAULT_NAME -and $env:AUTH_KEYVAULT_CERTNAME) {
    $authCert = $null
}
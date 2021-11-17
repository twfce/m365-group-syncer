$requiredModules = @(
    "Az"
    "AzTable",
    "Microsoft.Graph.Authentication"
)

if (-Not (Test-Path "$PSScriptRoot\modules")) { New-Item -Type Directory -Path "$PSScriptRoot\modules" }
foreach ($module in $requiredModules) {
    Save-Module -Path "$PSScriptRoot\modules" -Name $module
}
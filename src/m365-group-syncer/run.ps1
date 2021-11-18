# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

$groupMappingsTable = Prepare-StorageTable -TableName $env:GROUP_MAPPINGS_TABLE_NAME -ConnectionString $env:STORAGE_TABLE_CONNECTION -CreateTableIfNotExists
$groupMappings = Get-AzTableRow -table $groupMappingsTable
$groupMappings | Foreach-Object -Parallel {
    $_
}
param($Timer)

Import-Module Microsoft.Graph.Authentication

#region Authentication
Connect-MgGraph -ClientId $env:AUTH_CLIENT_ID -Certificate $authCert -TenantId $env:AUTH_TENANT_ID
#endregion

$groupMappingsTable = Prepare-StorageTable -TableName $env:GROUP_MAPPINGS_TABLE_NAME -ConnectionString $env:STORAGE_TABLE_CONNECTION -CreateTableIfNotExists
if ($env:INSERT_TEST_MAPPING) {
    Invoke-GroupMappingTestData -Table $groupMappingsTable
}

Get-AzTableRowAll -table $groupMappingsTable | Foreach-Object {    
    $targetGroupObject = Get-MgGroup -Filter "displayName eq '$($_.RowKey)'"
    if ($targetGroupObject.count -gt 1) {
        throw "[$($_.RowKey)] Too many groups returned. Cannot determine which group to use"
        exit
    }

    Write-Host "[$($_.RowKey)] Found group in Azure AD"
    $sourceGroupObjects = $_.SourceGroups | ConvertFrom-Json | ForEach-Object {
        Get-MgGroup -Filter "displayName eq '$_'"
    }

    Get-GroupMembers -Group $sourceGroupObjects[0].Id

}
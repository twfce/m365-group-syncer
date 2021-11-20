param($Timer)

#region Authentication
if (-Not (Test-GraphConnection)) {
    Connect-MgGraph -ClientId $env:AUTH_CLIENT_ID -Certificate $authCert -TenantId $env:AUTH_TENANT_ID
}
#endregion

$groupMappingsTable = Prepare-StorageTable -TableName $env:GROUP_MAPPINGS_TABLE_NAME -ConnectionString $env:STORAGE_TABLE_CONNECTION -CreateTableIfNotExists
$memberManagerQueue = Prepare-StorageQueue -QueueName "membermanagerqueue" -ConnectionString $env:STORAGE_QUEUE_CONNECTION -CreateQueueIfNotExists

if ($env:INSERT_TEST_MAPPING) {
    Invoke-GroupMappingTestData -Table $groupMappingsTable
}

Get-AzTableRowAll -table $groupMappingsTable | Foreach-Object {    
    $targetGroup = Get-MgGroup -Filter "displayName eq '$($_.RowKey)'"
    if ($targetGroup.count -gt 1) {
        throw "[$($_.RowKey)] Too many groups returned. Cannot determine which group to use"
        continue
    }
    $currentMembers = Get-GroupMembers -GroupId $targetGroup.Id

    Write-Host "[$($_.RowKey)] Found group in Azure AD"
    $sourceGroups = $_.SourceGroups | ConvertFrom-Json | ForEach-Object {
        Get-MgGroup -Filter "displayName eq '$_'"
    }
    $sourceMembers = $sourceGroups | Foreach-Object { Get-GroupMembers -GroupId $_.Id } | Sort-Object -Unique Id
    Write-Host "[$($_.RowKey)] Received $($sourceMembers.count) unique members from source groups"

    if ($currentMembers.count -gt 0) {
        $compare = Compare-Object -ReferenceObject $currentMembers.id -DifferenceObject $sourceMembers.id
        if ($compare.SideIndicator -contains "=>") {
            New-MemberManagerAction -TargetGroupId $targetGroup.id -Members ($compare | Where-Object {$_.SideIndicator -eq "=>"}).InputObject -Action "Add" -Queue $memberManagerQueue
        }
        if ($compare.SideIndicator -contains "<=") {
            New-MemberManagerAction -TargetGroupId $targetGroup.id -Members ($compare | Where-Object {$_.SideIndicator -eq "<="}).InputObject -Action "Remove" -Queue $memberManagerQueue
        }
    }
    else {
        New-MemberManagerAction -TargetGroupId $targetGroup.id -Members $sourceGroups.id -Action "Add" -Queue $memberManagerQueue
    }    
}
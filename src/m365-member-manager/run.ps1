param($QueueItem, $TriggerMetadata)

Write-Host "PowerShell queue trigger function received message: $($QueueItem | ConvertTo-Json )"

#region Authentication
if (-Not (Test-GraphConnection)) {
    Connect-MgGraph -ClientId $env:AUTH_CLIENT_ID -Certificate $authCert -TenantId $env:AUTH_TENANT_ID
}
#endregion

foreach ($member in $QueueItem["memberIds"]) {
    switch ($QueueItem["action"]) {
        "Add" {
            Write-Host "Adding $member to $($QueueItem["targetGroupId"])" 
            New-MgGroupMember -GroupId $QueueItem["targetGroupId"] -DirectoryObjectId $member
        }
        "Remove" { 
            Write-Host "Removing $member from $($QueueItem["targetGroupId"])"
            $uri = "https://graph.microsoft.com/v1.0/groups/{0}/members/{1}/`$ref" -f $QueueItem["targetGroupId"], $member
            Invoke-MgGraphRequest -Method DELETE -Uri $uri
         }
    }
}
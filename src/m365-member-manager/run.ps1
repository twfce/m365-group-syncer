param($QueueItem, $TriggerMetadata)

Write-Host "PowerShell queue trigger function received message: $($QueueItem | ConvertTo-Json)"

#region Authentication
if ($env:AUTH_CERTIFICATE_FILE) {
    $authCert = Prepare-Certificate -FilePath $env:AUTH_CERTIFICATE_FILE
}
elseif ($env:AUTH_KEYVAULT_NAME -and $env:AUTH_KEYVAULT_CERTNAME) {
    $authCert = $null
}

switch ($QueueItem["api"]) {
    "ExO" {
        Connect-ExchangeOnline -Organization $env:AUTH_TENANT_NAME `
            -AppId $env:AUTH_CLIENT_ID `
            -Certificate $authCert `
            -ErrorAction Stop `
            -ShowBanner:$false `
            -ShowProgress:$false `
            -CommandName Add-DistributionGroupMember, Remove-DistributionGroupMember
    }
    default {
        if (-Not (Test-GraphConnection)) {
            Connect-MgGraph -ClientId $env:AUTH_CLIENT_ID -Certificate $authCert -TenantId $env:AUTH_TENANT_ID
        }
    }
}
#endregion

foreach ($member in $QueueItem["memberIds"]) {
    switch ($QueueItem["action"]) {
        "Add" {
            Write-Host "Adding $member to $($QueueItem["targetGroup"]["id"])" 
            switch ($QueueItem["api"]) {
                "ExO" {
                    Add-DistributionGroupMember -Identity $QueueItem["targetGroup"].Mail -Member $member -BypassSecurityGroupManagerCheck                }
                default {
                    New-MgGroupMember -GroupId $QueueItem["targetGroup"].Id -DirectoryObjectId $member
                }
            }
        }
        "Remove" {
            Write-Host "Removing $member from $($QueueItem["targetGroup"]["id"])"
            switch ($QueueItem["api"]) {
               "ExO" { 
                    Remove-DistributionGroupMember -Identity $QueueItem["targetGroup"].Mail -Member $member -BypassSecurityGroupManagerCheck -Confirm:$false
                }
                default {
                    $uri = "https://graph.microsoft.com/v1.0/groups/{0}/members/{1}/`$ref" -f $QueueItem["targetGroup"]["id"], $member
                    Invoke-MgGraphRequest -Method DELETE -Uri $uri
                }
            }
         }
    }
}
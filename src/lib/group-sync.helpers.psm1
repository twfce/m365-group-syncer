function Invoke-GroupMappingTestData {
    Param (
        [Microsoft.Azure.Cosmos.Table.CloudTable] $Table
    )

    begin {
        $testMappings = @(
            [PSCustomObject] @{
                "PartitionKey" = "groupMappings"
                "RowKey" = "Target Group for m365-group-syncer"
                "Properties" = @{
                    "SourceGroups" = @("All Company", "Retail") | ConvertTo-Json
                    "MemberFilter" = ""
                    "MaxMembers" = 0
                }                
            },
            [PSCustomObject] @{
                "PartitionKey" = "groupMappings"
                "RowKey" = "Target Group for m365-group-syncer with MaxMembers"
                "Properties" = @{
                    "SourceGroups" = @("U.S. Sales") | ConvertTo-Json
                    "MemberFilter" = ""
                    "MaxMembers" = 1000
                }
            }
        )
    }
    process {
        foreach ($mapping in $testMappings) {
            if (-Not (Get-AzTableRow -table $Table -partitionKey $mapping.PartitionKey -rowKey $mapping.RowKey)) {
                Add-AzTableRow -table $Table `
                -partitionKey $mapping.PartitionKey `
                -rowKey $mapping.RowKey `
                -property $mapping.Properties
            }            
        }
    }
}

function Get-GroupMembers {
    Param (
        [string] $GroupId
    )

    $cache = @()
    $request = Invoke-MgGraphRequest -Method GET -Uri "v1.0/groups/$GroupId/members"
    do {
        $cache += $request.Value
        if ($request.Keys -contains '@odata.nextLink') {
            $request = Invoke-MgGraphRequest -Method GET -Uri $request.'@odata.nextLink'
        }
        else {
            break
        }
    } while ($true)

    $members = $cache | Select-Object @{n = "id"; e = { $_.id }}
    return $members
}

function Get-GroupMemberApi {
    Param (
        [Parameter(Mandatory = $true)]
        $Group
    )

    process {
        if ($Group.securityEnabled -and $Group.mailEnabled) {
            return "ExO"
        }
        return "Graph"
    }
}

function New-MemberManagerAction {
    Param (
        [Parameter(Mandatory = $true)]
        $TargetGroup,
        [Parameter(Mandatory = $true)]
        [string[]] $Members,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Add", "Remove")]
        [string] $Action,
        [ValidateSet("ExO", "Graph")]
        [string] $API = "Graph",
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Storage.Queue.CloudQueue] $Queue
    )

    begin {
        $message = @{
            "targetGroup" = $TargetGroup
            "memberIds" = $Members
            "action" = $Action
            "api" = $API
        } | ConvertTo-Json
    }
    process {
        $Queue.AddMessageAsync([Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($message))
    }
}

Export-ModuleMember -Function *
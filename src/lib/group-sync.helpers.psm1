function Invoke-GroupMappingTestData {
    Param (
        [CloudTable] $Table
    )

    begin {
        $testData = @(
            [PSCustomObject] @{
                "PartitionKey" = "groupMappings"
                "RowKey" = "Target Group for m365-group-syncer"
                "TargetGroups" = @("All Company", "Retail") | ConverTo-Json
                "MemberFilter" = ""
                "MaxMembers" = 0
            },
            [PSCustomObject] @{
                "PartitionKey" = "groupMappings"
                "RowKey" = "Target Group for m365-group-syncer with MaxMembers"
                "TargetGroups" = @("U.S. Sales") | ConverTo-Json
                "MemberFilter" = ""
                "MaxMembers" = 1000
            }
        )
    }
    process {
    }
    end {

    }
}

Export-ModuleMember -Function *
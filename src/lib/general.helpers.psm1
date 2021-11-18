
function Prepare-StorageTable {
    Param (
        [Parameter(Mandatory = $true)]
        [string] $TableName,
        [switch] $CreateTableIfNotExists,
        [Parameter(Mandatory = $true)]
        [string] $ConnectionString
    )

    $storageTableCtx = New-AzStorageContext -ConnectionString $ConnectionString
    if (-Not (Get-AzStorageTable -Name $TableName -Context $storageTableCtx -ErrorAction SilentlyContinue)) {
        Write-Host "[Prepare-StorageTable] Table $TableName does not exist."
        if ($CreateTableIfNotExists) {
            Write-Host "[Prepare-StorageTable] Creating empty table"
            return (New-AzStorageTable -Name $TableName -Context $storageTableCtx).CloudTable
        }        
    }
    else {
        return (Get-AzStorageTable -Name $TableName -Context $storageTableCtx).CloudTable
    }    
}

Export-ModuleMember -Function *
function Prepare-Certificate {
    Param (
        [Parameter(ParameterSetName="CertFile")]
        $FilePath,
        [Parameter(ParameterSetName="KeyVaultCert")]
        $VaultName,
        [Parameter(ParameterSetName="KeyVaultCert")]
        $CertificateName
    )

    begin {
        if ($PSBoundParameters.ContainsKey("FilePath")) {
            $certToImport = $FilePath
        }
        elseif ($PSBoundParameters.ContainsKey("VaultName") -and $PSBoundParameters.ContainsKey("CertificateName")) {
            $cert = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName
            $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $cert.Name        
            $secretValueText = ''
            $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
            try {
                $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
            } finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
            }
            $certToImport = [Convert]::FromBase64String($secretValueText) 
        }

        if ($PSVersionTable.Platform -ne 'Unix' -and -not $PSBoundParameters.ContainsKey("FilePath")) {
            $x509Cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
        }        
    }
    process {
        if (-Not $certToImport) {
            throw "No certificate to import"
        }

        if ($PSVersionTable.Platform -ne 'Unix' -and -not $PSBoundParameters.ContainsKey("FilePath")) {
            $x509Cert.Import($certToImport, "", "Exportable,PersistKeySet")
        }
        else {
            $x509Cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($FilePath)
        }
        
    }   
    end {
        $x509Cert
    }
}

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
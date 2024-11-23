param(
    $connectionString,
    $batchSize=100,
    $initialRoot='c:\'
)

if ($connectionString -like '')  {
    $connectionString = Get-Content -path 'dbConnectionString'
}

$WarningPreference = "SilentlyContinue"

Open-MySqlConnection -ConnectionName "sql" -ConnectionString $connectionString

Invoke-SQLQuery -ConnectionName "sql" -query "CALL reportFolder(@folderPath, @exist);" -parameters @{'folderPath'=$initialRoot;'exist'=1}

do {
    try {
        Write-Host "getNextFoldersForReview" -ForegroundColor Green
        $foldersToCheck = Invoke-SQLQuery -ConnectionName "sql" -query "CALL getNextFoldersForReview(@batchSize);" -parameters @{'batchSize'=$batchSize}

        foreach($folder in $foldersToCheck){
            write-host $folder.fullPath
            if (test-path $folder.fullPath) {
                try {
                    Get-ChildItem -Directory $folder.fullPath -ErrorAction Stop | ForEach-Object {
                        write-host $_.FullName
                        Invoke-SQLQuery -ConnectionName "sql" -query "CALL reportFolder(@folderPath, @exist);" -parameters @{'folderPath'=$_.FullName;'exist'=1} 
                    }
                } catch {
                    Invoke-SQLQuery -ConnectionName "sql" -query "CALL reportFolder(@folderPath, @exist);" -parameters @{'folderPath'=$folder.fullPath;'exist'=2}
                }
            } else {
                # folder does not exist any more (deleted)
                Invoke-SQLQuery -ConnectionName "sql" -query "CALL reportFolder(@folderPath, @exist);" -parameters @{'folderPath'=$folder.fullPath;'exist'=0}
            }
        }
    } catch {
        Write-Host "$($PSItem.ToString())" -ForegroundColor Red
    }
} while ($true)
param(
    $connectionString,
    $batchSize=5,
    $initialRoot='c:\'
)

if ($connectionString -like '')  {
    $connectionString = Get-Content -path 'dbConnectionString'
}

$WarningPreference = "SilentlyContinue"

Open-MySqlConnection -ConnectionName "sql" -ConnectionString $connectionString

do {
    Invoke-SQLQuery -ConnectionName "sql" -query "CALL reportFolder(@folderPath, @exist);" -parameters @{'folderPath'=$initialRoot;'exist'=1}

    $foldersToCheck = Invoke-SQLQuery -ConnectionName "sql" -query "CALL getNextFoldersForReview(@batchSize);" -parameters @{'batchSize'=50}

    foreach($folder in $foldersToCheck){
        write-host $folder.fullPath
        if (test-path $folder.fullPath) {
            Get-ChildItem -Directory $folder.fullPath | ForEach-Object {
                write-host $_.FullName
                Invoke-SQLQuery -ConnectionName "sql" -query "CALL reportFolder(@folderPath, @exist);" -parameters @{'folderPath'=$_.FullName;'exist'=1} 
            }
        } else {
            # folder does not exist any more (deleted)
            Invoke-SQLQuery -ConnectionName "sql" -query "CALL reportFolder(@folderPath, @exist);" -parameters @{'folderPath'=$folder.fullPath;'exist'=0}
        }
    }
    Start-Sleep -Seconds 1
} while ($true)
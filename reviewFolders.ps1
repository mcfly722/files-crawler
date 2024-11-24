param(
    $connectionString,
    $inputBatchSize = 100,
    $outputBatchSize = 200,
    $minimalSendIntervalSec = 5,
    $initialRoot = 'c:\Intel'
)

if ($connectionString -like '')  {
    $connectionString = Get-Content -path 'dbConnectionString'
}

$global:foldersBatch=[System.Collections.ArrayList]::new()
$global:foldersBatchLastSend = get-date
function appendFolder([hashtable]$folder, $minimalSendIntervalSec, $outputBatchSize) {
    $global:foldersBatch.Add($folder) > $null

    if (
        (((get-date)-$global:foldersBatchLastSend).TotalSeconds -gt $minimalSendIntervalSec) -or 
        ($global:foldersBatch.Count -ge $outputBatchSize)
        ) {
            $json = convertTo-Json -inputObject $global:foldersBatch -Compress
            Write-Host "reportFolders" -ForegroundColor Green
            Invoke-SQLQuery -ConnectionName "sql" -query "CALL reportFolders(@foldersJSON);" -parameters @{'foldersJSON'= $json} 
            $global:foldersBatch=[System.Collections.ArrayList]::new()
    }
}


$WarningPreference = "SilentlyContinue"

Open-MySqlConnection -ConnectionName "sql" -ConnectionString $connectionString

appendFolder @{'fullPath' = $initialRoot;'lastDeletionAt' = 'NULL'; 'error'= 0} 0 0


do {
    try {
        Write-Host "getNextFoldersForReview" -ForegroundColor Green
        $foldersToCheck = Invoke-SQLQuery -ConnectionName "sql" -query "CALL getNextFoldersForReview(@batchSize);" -parameters @{'batchSize' = $inputBatchSize}
        $foldersToCheck
        foreach($folder in $foldersToCheck){
            #write-host $folder.fullPath
            if (test-path $folder.fullPath) {
                try {
                    Get-ChildItem -Directory $folder.fullPath -ErrorAction Stop | ForEach-Object {
                        write-host $_.FullName
                        appendFolder @{'parentFolderId' = $folder.id;'fullPath' = $_.FullName; 'lastDeletionAt' = 'NULL'; 'error'= 0 } $minimalSendIntervalSec $outputBatchSize
                    }
                } catch {
                    appendFolder @{'parentFolderId' = $folder.id; 'fullPath' = $folder.fullPath; 'lastDeletionAt' = 'NULL'; 'error' = 1} $minimalSendIntervalSec $outputBatchSize
                }
            } else {
                # folder does not exist any more (deleted)
                Write-Host "$($folder.fullPath) does not exist eny more" -ForegroundColor Yellow
                appendFolder @{'parentFolderId' = $folder.id; 'fullPath' = $folder.fullPath; 'lastDeletionAt' = (get-date).ToString("yyyy-MM-dd HH:mm:ss"); 'error' = 0} $minimalSendIntervalSec $outputBatchSize
            }
        }
    } catch {
        Write-Host "$($PSItem.ToString())" -ForegroundColor Red
    }
} while ($true)
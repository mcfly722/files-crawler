param(
    $connectionString,
    $inputBatchSize = 100,
    $outputBatchSize = 200,
    $minimalSendIntervalSec = 60,
    $initialRoot = 'c:\'
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

appendFolder @{'fullPath'=$initialRoot;'exist'=1} 0 0


do {
    try {
        Write-Host "getNextFoldersForReview" -ForegroundColor Green
        $foldersToCheck = Invoke-SQLQuery -ConnectionName "sql" -query "CALL getNextFoldersForReview(@batchSize);" -parameters @{'batchSize' = $inputBatchSize}

        foreach($folder in $foldersToCheck){
            #write-host $folder.fullPath
            if (test-path $folder.fullPath) {
                try {
                    Get-ChildItem -Directory $folder.fullPath -ErrorAction Stop | ForEach-Object {
                        #write-host $_.FullName
                        appendFolder @{'fullPath' = $_.FullName; 'exist' = 1} $minimalSendIntervalSec $outputBatchSize
                    }
                } catch {
                    appendFolder @{'fullPath' = $folder.fullPath; 'exist' = 2} $minimalSendIntervalSec $outputBatchSize
                }
            } else {
                # folder does not exist any more (deleted)
                appendFolder @{'fullPath' = $folder.fullPath; 'exist' = 0} $minimalSendIntervalSec $outputBatchSize
            }
        }
    } catch {
        Write-Host "$($PSItem.ToString())" -ForegroundColor Red
    }
} while ($true)
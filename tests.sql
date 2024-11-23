-- Check case when same folder reported  several times that there are no duplicates will be created
CALL reportFolder('folder1');
CALL reportFolder('folder1');
CALL reportFolder('folder1');
CALL reportFolder('folder2');
CALL reportFolder('folder2');
SELECT COUNT(*), fullPath FROM folders GROUP BY fullPath;

CALL reportFile(1, 'file1');
CALL reportFile(1, 'file1');
CALL reportFile(1, 'file2');
-- CALL reportFile(2, 'file2');
-- DELETE FROM files.hashes WHERE SHA256='';
-- Check case when same folder reported  several times that there are no duplicates will be created
CALL reportHash(1,'hash1');
CALL reportHash(1,'hash1');


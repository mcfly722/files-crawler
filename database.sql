CREATE SCHEMA `files` ;
USE `files`;

DROP TABLE IF EXISTS files;
DROP TABLE IF EXISTS folders;
DROP TABLE IF EXISTS hashes;

DROP PROCEDURE IF EXISTS `reportFolder`;
DROP PROCEDURE IF EXISTS `reportFile`;
DROP PROCEDURE IF EXISTS `reportHash`;

CREATE TABLE `folders` (
  `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `parentFolderId` BIGINT UNSIGNED  NULL,
  `fullPath`       VARCHAR(260)     NOT NULL,
  `lastReviewAt`   TIMESTAMP(6)     NULL,
  `lastDeletionAt` TIMESTAMP(6)     NULL,
  `error`  INT     UNSIGNED         NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX (`fullPath`),
  FOREIGN KEY (`parentFolderId`) REFERENCES folders(id) ON DELETE RESTRICT
);

CREATE INDEX parentFolderIdIdx              ON `folders` (parentFolderId);
CREATE INDEX lastReviewAtIdx                ON `folders` (lastReviewAt);
CREATE INDEX lastReviewAtAndLastDeleteAtIdx ON `folders` (lastReviewAt, lastDeletionAt);

DELIMITER $$
$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getNextFoldersForReview`(amount INT UNSIGNED)
BEGIN
  DECLARE lock_acquired INT DEFAULT 0;
  SET lock_acquired = GET_LOCK('getNextFoldersForRevie_lock', 60); -- Timeout of 60 seconds
  IF lock_acquired = 1 THEN
	  SET @current_date = NOW(6);
	  UPDATE folders SET lastReviewAt = @current_date WHERE lastDeletionAt IS NULL ORDER BY lastReviewAt LIMIT amount;
	  SELECT id, fullPath FROM folders WHERE lastReviewAt = @current_date;
    DO RELEASE_LOCK('getNextFoldersForRevie_lock');
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Could not acquire the lock';
  END IF;
END;

CREATE PROCEDURE `reportFolders` (foldersJSON TEXT)
BEGIN
	INSERT INTO folders (parentFolderId, fullPath, lastDeletionAt, error)
    SELECT parentFolderId, fullPath, lastDeletionAt, error
    FROM JSON_TABLE(
		foldersJSON, '$[*]' COLUMNS(
        parentFolderId BIGINT UNSIGNED PATH '$.parentFolderId',
        fullPath       VARCHAR(260)    PATH '$.fullPath',
        lastDeletionAt TIMESTAMP(6)    PATH '$.lastDeletionAt',
        error          INT UNSIGNED    PATH '$.error'
      ) 
    ) AS json
    ON DUPLICATE KEY UPDATE
      folders.parentFolderId=json.parentFolderId,
      folders.fullPath      =json.fullPath,
      folders.lastDeletionAt=json.lastDeletionAt,
      folders.error         =json.error;
END

$$
DELIMITER ;

/*
CREATE TABLE `hashes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `SHA256` VARCHAR(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX (`SHA256`)
);

CREATE TABLE `files` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parentFolderId` BIGINT UNSIGNED NOT NULL,
  `hashId` BIGINT UNSIGNED NULL,
  `name` VARCHAR(256) NOT NULL,
  `lastSeenAt` TIMESTAMP(6) NULL,
  PRIMARY KEY (`id`,`parentFolderId`,`name`),
  FOREIGN KEY (`parentFolderId`) REFERENCES folders(id) ON DELETE RESTRICT,
  FOREIGN KEY (`hashId`) REFERENCES hashes(id) ON DELETE RESTRICT,
  UNIQUE INDEX (`id`),
  UNIQUE INDEX (`parentFolderId`,`name`)
);

DELIMITER $$
$$

CREATE PROCEDURE `reportFile` (folderID bigint, fileName varchar(256))
BEGIN
	INSERT INTO files (parentFolderId, name) VALUES (folderId, fileName) ON DUPLICATE KEY UPDATE parentFolderId=folderId, name=fileName;
END;

CREATE PROCEDURE `reportHash` (fileId BIGINT, SHA256 varchar(64))
BEGIN
	START TRANSACTION;
		INSERT INTO hashes (SHA256) VALUES (SHA256) ON DUPLICATE KEY UPDATE SHA256=SHA256;
		UPDATE files SET hashId=LAST_INSERT_ID() WHERE files.id=fileId;
	COMMIT;
END;


$$
DELIMITER ;
*/

CREATE SCHEMA `files` ;
USE `files`;

DROP TABLE IF EXISTS files;
DROP TABLE IF EXISTS folders;
DROP TABLE IF EXISTS hashes;

DROP PROCEDURE IF EXISTS `reportFolder`;
DROP PROCEDURE IF EXISTS `reportFile`;
DROP PROCEDURE IF EXISTS `reportHash`;

CREATE TABLE `folders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `fullPath` VARCHAR(260) NOT NULL,
  `exist` TINYINT  DEFAULT 1,
  `lastReviewAt` TIMESTAMP(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX (`fullPath`)
);

CREATE INDEX lastReviewAtIdx ON `folders` (lastReviewAt);
CREATE INDEX lastReviewAtAndExistIdx ON `folders` (lastReviewAt, exist);

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `getNextFoldersForReview`(amount INT UNSIGNED)
BEGIN
	SET @current_date = NOW(6);
	UPDATE folders SET lastReviewAt = @current_date WHERE exist=1 ORDER BY lastReviewAt LIMIT amount;
	SELECT Id, fullPath FROM folders WHERE lastReviewAt = @current_date;
END;

CREATE PROCEDURE `reportFolders` (foldersJSON TEXT)
BEGIN
	INSERT INTO folders (fullPath, exist)
    SELECT fullPath, exist
    FROM JSON_TABLE(
		foldersJSON, '$[*]' COLUMNS(
			fullPath VARCHAR(260) PATH '$.fullPath',
            exist TINYINT PATH '$.exist'
        ) 
    ) AS json
    ON DUPLICATE KEY UPDATE folders.fullPath=json.fullPath, folders.exist=json.exist;
END

$$
DELIMITER ;
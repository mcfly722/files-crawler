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
  `lastReviewAt` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX (`fullPath`)
);

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
  `lastSeenAt` DATETIME NULL,
  PRIMARY KEY (`id`,`parentFolderId`,`name`),
  FOREIGN KEY (`parentFolderId`) REFERENCES folders(id) ON DELETE RESTRICT,
  FOREIGN KEY (`hashId`) REFERENCES hashes(id) ON DELETE RESTRICT,
  UNIQUE INDEX (`id`),
  UNIQUE INDEX (`parentFolderId`,`name`)
);


DELIMITER $$
USE `files`$$
CREATE PROCEDURE `reportFolder` (folderPath  varchar(260))
BEGIN
	INSERT INTO folders (fullPath) VALUES (folderPath) ON DUPLICATE KEY UPDATE fullPath=folderPath;
END$$
DELIMITER ;

DELIMITER $$
USE `files`$$
CREATE PROCEDURE `reportFile` (folderID bigint, fileName varchar(256))
BEGIN
	INSERT INTO files (parentFolderId, name) VALUES (folderId, fileName) ON DUPLICATE KEY UPDATE parentFolderId=folderId, name=fileName;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS `reportHash`;
DELIMITER $$
USE `files`$$
CREATE PROCEDURE `reportHash` (fileId BIGINT, SHA256 varchar(64))
BEGIN
	START TRANSACTION;
		INSERT INTO hashes (SHA256) VALUES (SHA256) ON DUPLICATE KEY UPDATE SHA256=SHA256;
		UPDATE files SET hashId=LAST_INSERT_ID() WHERE files.id=fileId;
	COMMIT;
END$$
DELIMITER ;
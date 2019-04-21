-- 'a.avi',
-- '1390896180',
-- '278.part',
-- '20190103024608',
-- '20190103110115',
-- '20190103110115',
-- '70',
-- '33',
-- '283051727',
-- 'Auto',
-- '[Artist]',
-- '[Album]',
-- '[Title]',
-- '8624',
-- '1279',
-- 'xvid',
-- '',
-- '9E62CE1A9A0510FA409703F8E87E4300',


-- Filename
-- File Size
-- Temporary Filename
-- Last Written (UTC)
-- Last Posted (UTC)
-- Last Shared (UTC)
-- Requests Total
-- Requests Accepted
-- Bytes Uploaded
-- Upload Priority
-- Artist
-- Album
-- Title
-- Length (sec)
-- Bitrate
-- Codec
-- File Type
-- File Hash

CREATE TABLE IF NOT EXISTS `filecheck`.`known_met` (
  `File_Hash` CHAR(32) CHARACTER SET 'ascii' NOT NULL COMMENT 'File Hash',
  `Filename` VARCHAR(255) CHARACTER SET 'utf8' NOT NULL COMMENT 'Filename',
  `File_Size` BIGINT(20) NULL DEFAULT NULL COMMENT 'File Size',
  `File_Type` VARCHAR(255) CHARACTER SET 'utf8' NULL DEFAULT NULL COMMENT 'File Type',
  `Temporary_Filename` VARCHAR(12) CHARACTER SET 'utf8' NULL DEFAULT NULL COMMENT 'Temporary Filename',
  `Last_Written` DATETIME NULL DEFAULT NULL COMMENT 'Last Written (UTC)',
  `Last_Posted` DATETIME NULL DEFAULT NULL COMMENT 'Last Posted (UTC)',
  `Last_Shared` DATETIME NULL DEFAULT NULL COMMENT 'Last Shared (UTC)',
  `Requests_Total` INT(11) NULL DEFAULT NULL COMMENT 'Requests Total',
  `Requests_Accepted` INT(11) NULL DEFAULT NULL COMMENT 'Requests Accepted',
  `Bytes_Uploaded` BIGINT(20) NULL DEFAULT NULL COMMENT 'Bytes Uploaded',
  `Upload_Priority` VARCHAR(6) CHARACTER SET 'utf8' NULL DEFAULT NULL COMMENT 'Upload Priority',
  `Artist` VARCHAR(255) CHARACTER SET 'utf8' NULL DEFAULT NULL COMMENT 'Artist',
  `Album` VARCHAR(255) CHARACTER SET 'utf8' NULL DEFAULT NULL COMMENT 'Album',
  `Title` VARCHAR(255) CHARACTER SET 'utf8' NULL DEFAULT NULL COMMENT 'Title',
  `Length` INT(11) NULL DEFAULT NULL COMMENT 'Length (sec)',
  `Bitrate` INT(11) NULL DEFAULT NULL COMMENT 'Bitrate',
  `Codec` VARCHAR(255) CHARACTER SET 'utf8' NULL DEFAULT NULL COMMENT 'Codec',
  PRIMARY KEY (`File_Hash`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

-- 
--  NextPress Database & User setup
--  Copyright (C) 2017 Lowadobe Web Services, LLC 
--  web: http://nextpress.org/
--  email: lowadobe@gmail.com
--

CREATE DATABASE IF NOT EXISTS `nextData`;
CREATE DATABASE IF NOT EXISTS `nextPublic`;
CREATE DATABASE IF NOT EXISTS `nextAdmin`;

DELIMITER $$
CREATE PROCEDURE `addWebServerUser` ()
BEGIN
    DECLARE usr_exists CHAR(16) DEFAULT NULL;
    SELECT `User` INTO usr_exists FROM `mysql`.`user` WHERE `User` = 'nextUser';
    IF usr_exists IS NULL THEN
        CREATE USER 'nextUser'@'localhost' IDENTIFIED BY 'nxt';
    END IF;
END $$
DELIMITER ;

CALL `addWebServerUser`();
DROP PROCEDURE `addWebServerUser`;

GRANT SELECT (`name`,`param_list`,`db`,`type`) ON `mysql`.`proc` 
    TO 'nextUser'@'localhost';
GRANT EXECUTE ON `nextPublic`.* TO 'nextUser'@'localhost';
GRANT EXECUTE ON `nextAdmin`.* TO 'nextUser'@'localhost';


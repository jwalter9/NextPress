
CREATE DATABASE IF NOT EXISTS `nextData`;
CREATE DATABASE IF NOT EXISTS `nextPublic`;
CREATE DATABASE IF NOT EXISTS `nextAdmin`;

CREATE USER 'nextUser'@'localhost' IDENTIFIED BY 'nxt';
GRANT SELECT (`name`,`param_list`,`db`,`type`) ON `mysql`.`proc` 
    TO 'nextUser'@'localhost';
GRANT EXECUTE ON `nextPublic`.* TO 'nextUser'@'localhost';
GRANT EXECUTE ON `nextAdmin`.* TO 'nextUser'@'localhost';


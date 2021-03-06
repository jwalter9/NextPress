-- 
--  NextPress Core Admin (SSL) Procedures
--  Copyright (C) 2017 Lowadobe Web Services, LLC 
--  web: http://nextpress.org/
--  email: lowadobe@gmail.com
--

DELIMITER $$

DROP PROCEDURE IF EXISTS `adminMenu` $$
CREATE PROCEDURE `adminMenu` ()
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, NULL);
    SELECT menu.* FROM `nextData`.`admin_links` AS menu
        JOIN `nextData`.`role_admin_links` 
            ON menu.`id` = `role_admin_links`.`idLink`
        JOIN `nextData`.`user_roles`
            ON `role_admin_links`.`idRole` = `user_roles`.`idRole`
                AND `user_roles`.`idUser` = userId
        GROUP BY menu.`id` ORDER BY menu.`id`;
    SET @domain = `nextData`.`getHost`(@mvp_headers);
END $$

DROP PROCEDURE IF EXISTS `Login` $$
CREATE PROCEDURE `Login` (IN eaddr VARCHAR(1024), IN passwd VARCHAR(256),
                          OUT canRegister VARCHAR(8), OUT redir TEXT)
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SELECT `id` INTO userId FROM `nextData`.`users`
        WHERE `email` = eaddr AND `password` = SHA2(passwd, 512) AND `prohibited` = 0
        LIMIT 1;
    IF userId > 0 THEN
        SELECT `redirect` INTO redir FROM `nextData`.`sessions`
            WHERE `id` = @mvp_session AND `ipAddress` = @mvp_remoteip;
        IF redir IS NULL OR redir = '' OR redir = 'Login' THEN
            SET redir = 'Dashboard';
        END IF;
        REPLACE INTO `nextData`.`sessions` (`id`,`idUser`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, userId, @mvp_remoteip, 'Dashboard');
        SET @mvp_template = 'redirect';
        SET @mvp_layout = 'popup';
    ELSE
        IF eaddr IS NOT NULL AND eaddr != '' THEN
            SET @err = 'Sorry, we didn&squot;t recognize your login credentials.';
        END IF;
    END IF;
    SET canRegister = LOWER(`nextData`.`getConfig`('Site','registration'));
END $$

DROP PROCEDURE IF EXISTS `Logout` $$
CREATE PROCEDURE `Logout` ()
BEGIN
    DELETE FROM `nextData`.`sessions` 
        WHERE `id` = @mvp_session AND `ipAddress` = @mvp_remoteip;
    SET @err = 'Logout Successful';
    SET @mvp_template = 'Login';
END $$

DROP PROCEDURE IF EXISTS `ForgotPassword` $$
CREATE PROCEDURE `ForgotPassword` (IN eaddr VARCHAR(256))
BEGIN
    DECLARE idUsr, retVal BIGINT DEFAULT 0;
    DECLARE vhash VARCHAR(32);
    DECLARE ebody TEXT DEFAULT '';
    SELECT `id` INTO idUsr FROM `nextData`.`users`
        WHERE `email` = eaddr LIMIT 1;
    IF idUsr = 0 THEN
        SET @err = CONCAT('The email address ',eaddr,' is not linked to an account.');
    ELSE
        SET vhash = MD5(CONCAT(@mvp_remoteip, RAND()));
        SET ebody = np_loadfile(CONCAT(`nextData`.`getConfig`('Site','tplroot'),
                '/admin/email/ForgotPassword.tpl'));
        IF ebody != '' THEN
            SET ebody = REPLACE(ebody, '<# RECIPIENT #>', eaddr);
            SET ebody = REPLACE(ebody, '<# FROM #>', 
                `nextData`.`getConfig`('Site','fromEmail'));
            SET ebody = REPLACE(ebody, '<# VHASH #>', vhash);
            SET ebody = REPLACE(ebody, '<# DOMAIN #>', 
                `nextData`.`getHost`(@mvp_headers));
            SET retVal = emailer(eaddr, ebody, 
                `nextData`.`getConfig`('Site','mailServer'), 
                `nextData`.`getConfig`('Site','fromEmail'));
            IF retVal != 0 THEN
                SET @err = 'Problem sending password reset email.';
    			INSERT INTO `nextData`.`mail_errors` (`theDate`,`errors`) 
    			    VALUES (NOW(), CONCAT('Error ',retVal,' for addr ',eaddr));
    		ELSE
                SET @err = 'Password reset email has been sent.';
    		    UPDATE `nextData`.`users` SET `verifyCode` = vhash WHERE `id` = idUsr;
    		END IF;
        ELSE
            INSERT INTO `nextData`.`mail_errors` (`theDate`,`errors`) 
                VALUES (NOW(), 'ForgotPassword template appears to be missing or empty.');
            SET @err = CONCAT('Problem sending email (missing template)');
        END IF;
    END IF;
    SET @mvp_template = 'Login';
END $$

DROP PROCEDURE IF EXISTS `Register` $$
CREATE PROCEDURE `Register`(IN eaddr VARCHAR(256))
BEGIN
    DECLARE idUsr, retVal, subscriberRoleId BIGINT DEFAULT 0;
    DECLARE vhash VARCHAR(32);
    DECLARE ebody TEXT DEFAULT '';
    SELECT `id` INTO idUsr FROM `nextData`.`users`
        WHERE `email` = eaddr LIMIT 1;
    IF idUsr > 0 THEN
        SET @err = CONCAT('The email address ',eaddr,' is already linked to an account.');
    ELSE
        IF is_email(eaddr) = 0 THEN
            SET vhash = MD5(CONCAT(@mvp_remoteip, RAND()));
            INSERT INTO `nextData`.`users` (`email`, `verifyCode`)
                VALUES (eaddr, vhash);
            SET idUsr = LAST_INSERT_ID();
            SET ebody = np_loadfile(CONCAT(`nextData`.`getConfig`('Site','tplroot'),
                '/admin/email/Register.tpl'));
            IF ebody != '' THEN
                SET ebody = REPLACE(ebody, '<# RECIPIENT #>', eaddr);
                SET ebody = REPLACE(ebody, '<# FROM #>', 
                    `nextData`.`getConfig`('Site','fromEmail'));
                SET ebody = REPLACE(ebody, '<# VHASH #>', vhash);
                SET ebody = REPLACE(ebody, '<# DOMAIN #>', 
                    `nextData`.`getHost`(@mvp_headers));
                SET retVal = emailer(eaddr, ebody, 
                    `nextData`.`getConfig`('Site','mailServer'), 
                    `nextData`.`getConfig`('Site','fromEmail'));
                IF retVal != 0 THEN
                    SET @err = 'Problem sending registration email.';
        			INSERT INTO `nextData`.`mail_errors` (`theDate`,`errors`) 
        			    VALUES (NOW(), CONCAT('Error ',retVal,' for addr ',eaddr));
        			DELETE FROM `nextData`.`users` WHERE `id` = idUsr;
        		ELSE
        		    SELECT `id` INTO subscriberRoleId FROM `nextData`.`roles`
        		        WHERE `label` = 'Subscriber' LIMIT 1;
        		    INSERT INTO `nextData`.`user_roles`(`idUser`,`idRole`)
        		        VALUES (idUsr, subscriberRoleId);
                    SET @err = 'Registration email has been sent.';
        		END IF;
            ELSE
                INSERT INTO `nextData`.`mail_errors` (`theDate`,`errors`) 
                    VALUES (NOW(), 'Registration template appears to be missing or empty.');
                SET @err = 'Problem sending email (missing template)';
                DELETE FROM `nextData`.`users` WHERE `id` = idUsr;
            END IF;
        ELSE
            SET @err = CONCAT('The email address ',eaddr,' did not pass validation test.');
        END IF;
    END IF;
    SET @mvp_template = 'Login';
END $$

DROP PROCEDURE IF EXISTS `Verify` $$
CREATE PROCEDURE `Verify`(IN vcode VARCHAR(32), OUT notAvail VARCHAR(4))
BEGIN
    DECLARE idUsr INT DEFAULT 0;
    SELECT `id` INTO idUsr FROM `nextData`.`users`
        WHERE `verifyCode` = vcode LIMIT 1;
    IF idUsr > 0 AND LENGTH(vcode) = 32 THEN
        DELETE FROM `nextData`.`sessions` WHERE `id` = @mvp_session;
        INSERT INTO `nextData`.`sessions` (`id`, `idUser`, `ipAddress`) 
            VALUES (@mvp_session, idUsr, @mvp_remoteip);
        SET @mvp_template = 'MyProfile';
        SET @err = 'Please enter a new password.';
        SELECT * FROM `nextData`.`users` WHERE `id` = userId;
        SET notAvail = `nextData`.`getConfig`('Site','notifications');
    ELSE
        SET @err = 'Unrecognized Verification Code';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Dashboard` $$
CREATE PROCEDURE `Dashboard` ()
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, NULL);
    IF userId > 0 THEN
        CALL `adminMenu`();
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in.';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Dashboard');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Pages` $$
CREATE PROCEDURE `Pages` ()
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SET @err = `nextData`.`refreshPages`();
        SELECT * FROM `nextData`.`pages` ORDER BY `published` DESC, `tpl`;
        CALL `adminMenu`();
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Pages');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `UpdatePage` $$
CREATE PROCEDURE `UpdatePage` (IN pageTpl VARCHAR(512), IN pageUri VARCHAR(512),
                               IN pageMobile TINYINT, IN pagePublished TINYINT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF pageUri IS NULL THEN
        SET pageUri = '';
    END IF;
    IF pageMobile IS NULL THEN
        SET pageMobile = 0;
    END IF;
    IF pagePublished IS NULL THEN
        SET pagePublished = 0;
    END IF;
    
    IF userId > 0 THEN
        UPDATE `nextData`.`pages` SET `uri` = pageUri, `mobile` = pageMobile
            WHERE `tpl` = pageTpl;
        SELECT COUNT(`tpl`) INTO chk FROM `nextData`.`pages`
            WHERE `tpl` = pageTpl AND `published` > -1;
        IF chk > 0 THEN
            UPDATE `nextData`.`pages` SET `published` = pagePublished 
                WHERE `tpl` = pageTpl;
        END IF;
        SELECT * FROM `nextData`.`pages` ORDER BY `published` DESC, `tpl`;
        CALL `adminMenu`();
        SET @mvp_template = 'Pages';
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Pages');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `addMedia` $$
CREATE PROCEDURE `addMedia` (IN upload VARCHAR(1024), OUT newId BIGINT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    DECLARE nUri, tUri, fext VARCHAR(1024) DEFAULT '';
    SET @mvp_layout = 'popup';
    SET newId = 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId = 0 THEN
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    END IF;
    IF userId = 0 THEN
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author');
    END IF;
    IF userId > 0 THEN
        IF upload IS NOT NULL AND upload != '' THEN
            SET fext = upload;
            WHILE LOCATE('.', fext) > 0 DO
                SET fext = SUBSTR(fext, LOCATE('.', fext) + 1);
            END WHILE;
            IF `nextData`.`isImage`(upload) THEN
                INSERT INTO `nextData`.`media` 
                    (`idAuthor`,`uri`,`thumb`,`isImage`,`dtAdded`)
                    VALUES (userId, '', '', 1, NOW());
                SET newId = LAST_INSERT_ID();
                SET nUri = CONCAT('/media/images/', newId, '.', fext);
                SET chk = convert_img(
                    upload,
                    CONCAT(`nextData`.`getConfig`('Site','webroot'), nUri),
                    `nextData`.`getConfig`('Media','mediaResize')
                    );
                IF chk != 0 THEN
                    SET @err = CONCAT('Error processing image file: ',chk);
                ELSE
                    UPDATE `nextData`.`media` SET `uri` = nUri WHERE `id` = newId;
                    SET tUri = CONCAT('/media/images/thumb_', newId, '.', fext);
                    SET chk = convert_img(
                        upload,
                        CONCAT(`nextData`.`getConfig`('Site','webroot'), tUri),
                        `nextData`.`getConfig`('Media','mediaThumbsize')
                        );
                    IF chk != 0 THEN
                        SET tUri = NULL;
                    ELSE
                        UPDATE `nextData`.`media` SET `thumb` = tUri WHERE `id` = newId;
                    END IF;
                END IF;
            ELSE
                INSERT INTO `nextData`.`media` 
                    (`idAuthor`,`uri`,`thumb`,`isImage`,`dtAdded`)
                VALUES 
                    (userId, '', '/media/images/file_thumb.png', 0, NOW());
                SET newId = LAST_INSERT_ID();
                SET nUri = CONCAT('/media/files/', newId, '.', fext);
                SET chk = file_copy(upload,
                        CONCAT(`nextData`.`getConfig`('Site','webroot'), nUri));
                IF chk != 0 THEN
                    SET @err = CONCAT('Error processing media file: ',chk);
                ELSE
                    UPDATE `nextData`.`media` SET `uri` = nUri WHERE `id` = newId;
                END IF;
            END IF;
        END IF;
        IF newId > 0 THEN
            SELECT * FROM `nextData`.`media` WHERE `id` = newId;
            SET @mvp_template = 'MediaAdded';
        END IF;
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin, Editor or Author privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'addMedia');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Users` $$
CREATE PROCEDURE `Users` (INOUT srch VARCHAR(1024), INOUT roleId BIGINT)
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    DECLARE srchTerm VARCHAR(1024) DEFAULT '';
    IF srch IS NOT NULL THEN
        SET srchTerm = LOWER(srch);
    END IF;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        IF roleId IS NOT NULL AND roleId > 0 THEN
            SELECT `users`.*, `nextData`.`listRoles`(`id`) AS roleList
                FROM `nextData`.`users` JOIN `nextData`.`user_roles` 
                    ON `users`.`id` = `user_roles`.`idUser`
                    AND `user_roles`.`idRole` = roleId
                WHERE LOWER(`displayName`) LIKE CONCAT('%',srchTerm,'%') OR
                      LOWER(`email`) LIKE CONCAT('%',srchTerm,'%') OR
                      LOWER(`url`) LIKE CONCAT('%',srchTerm,'%')
                GROUP BY `id` ORDER BY `id` LIMIT 50;
        ELSE
            SELECT `users`.*, `nextData`.`listRoles`(`id`) AS roleList
                FROM `nextData`.`users`
                WHERE LOWER(`displayName`) LIKE CONCAT('%',srchTerm,'%') OR
                      LOWER(`email`) LIKE CONCAT('%',srchTerm,'%') OR
                      LOWER(`url`) LIKE CONCAT('%',srchTerm,'%')
                ORDER BY `id` LIMIT 50;
        END IF;
        CALL `adminMenu`();
        SELECT * FROM `nextData`.`roles`;
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 
                    CONCAT('Users?srch=',url_encode(srch),
                    '&roleId=',url_encode(roleId)));
    END IF;
END $$

DROP PROCEDURE IF EXISTS `prohibitUser` $$
CREATE PROCEDURE `prohibitUser`(IN idUser BIGINT, IN prohib TINYINT)
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        UPDATE `nextData`.`users` SET `prohibited` = prohib WHERE `id` = idUser;
    ELSE
        SET @err = 'Please log in with Admin privileges';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `UserRoles` $$
CREATE PROCEDURE `UserRoles` (IN idUsr BIGINT)
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SELECT * FROM `nextData`.`users` WHERE `id` = idUsr;
        SELECT * FROM `nextData`.`user_roles` WHERE `idUser` = idUsr;
        SELECT * FROM `nextData`.`roles`;
        CALL `adminMenu`();
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, CONCAT('UserRoles?idUsr=',idUsr));
    END IF;
END $$

DROP PROCEDURE IF EXISTS `setUserRole` $$
CREATE PROCEDURE `setUserRole`(IN idUsr BIGINT, IN roleId BIGINT, IN invRev TINYINT)
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        IF invRev = 1 THEN
            REPLACE INTO `nextData`.`user_roles` (`idUser`,`idRole`)
                VALUES (idUsr, roleId);
        ELSE
            DELETE FROM `nextData`.`user_roles` 
                WHERE `idUser` = idUsr AND `idRole` = roleId;
        END IF;
    ELSE
        SET @err = 'Please log in with Admin privileges';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `MyProfile` $$
CREATE PROCEDURE `MyProfile`(IN dname VARCHAR(1024), IN eml VARCHAR(1024), 
                             IN uurl VARCHAR(1024), IN notArt TINYINT, 
                             IN avFile VARCHAR(1024), OUT notAvail VARCHAR(4))
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, NULL);
    IF userId > 0 THEN
        IF dname IS NOT NULL AND dname != '' AND eml IS NOT NULL AND eml != '' THEN
            UPDATE `nextData`.`users` SET
                `displayName` = dname,
                `email` = eml,
                `url` = uurl,
                `notifyArticles` = notArt
            WHERE `id` = userId;
        END IF;
        IF avFile IS NOT NULL AND `nextData`.`isImage`(avFile) THEN
            SET chk = convert_img(
                avFile,
                CONCAT(`nextData`.`getConfig`('Site','webroot'),
                       '/media/avatars/',userId,'.png'),
                `nextData`.`getConfig`('Media','avatarResize')
                );
            IF chk != 0 THEN
                SET @err = CONCAT('Error processing image file: ',chk);
            ELSE
                UPDATE `nextData`.`users` 
                    SET `avatarUri` = CONCAT('/media/avatars/',userId,'.png')
                    WHERE `id` = userId;
            END IF;
        END IF;
        SELECT * FROM `nextData`.`users` WHERE `id` = userId;
        SET notAvail = `nextData`.`getConfig`('Site','notifications');
        CALL `adminMenu`();
    ELSE
        SET @err = 'Please log in.';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `updatePass` $$
CREATE PROCEDURE `updatePass` (IN newPass TEXT, IN oldPass TEXT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, NULL);
    IF userId > 0 THEN
        SELECT COUNT(`id`) INTO chk FROM `nextData`.`users`
            WHERE `id` = userId AND `password` = SHA2(oldPass, 512);
        IF chk = 1 THEN
            UPDATE `nextData`.`users` 
                SET `password` = SHA2(newPass, 512) WHERE `id` = userId;
        ELSE
            SET @err = 'Current Password does not match.';
        END IF;
    ELSE
        SET @err = 'Please log in.';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Configuration` $$
CREATE PROCEDURE `Configuration` ()
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SELECT *, REPLACE(`val`,'"','&quot;') AS escVal 
            FROM `nextData`.`config` ORDER BY `ord`;
        SELECT * FROM `nextData`.`config_selection`;
        CALL `adminMenu`();
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Configuration');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `setConfig` $$
CREATE PROCEDURE `setConfig` (IN cid VARCHAR(32), IN pid VARCHAR(128), IN cval TEXT)
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SET @err = `nextData`.`setConfig`(pid, cid, REPLACE(cval, '&quot;', '"'));
        IF @err < 1 THEN
            SET @err = 'This configuration item does not exist?';
        ELSE
            SET @err = '';
        END IF;
    ELSE
        SET @err = 'Please log in with Admin privileges';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Articles` $$
CREATE PROCEDURE `Articles` (OUT earliest BIGINT, OUT canPublish VARCHAR(4))
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    IF userId > 0 THEN
        SELECT `articles`.`id`,`articles`.`teaser`,`articles`.`title`, 
            `articles`.`dtPublish`,`articles`.`uri`,
            `nextData`.`published`(`dtPublish`) AS pubDate,
            `users`.`displayName`,`users`.`avatarUri`
            FROM `nextData`.`articles` 
            JOIN `nextData`.`users` ON `articles`.`idAuthor` = `users`.`id`
            ORDER BY `articles`.`id` DESC LIMIT 20;
        SET earliest = 0;
        SELECT MIN(`id`) INTO earliest FROM `nextData`.`articles`;
        CALL `adminMenu`();
    ELSE
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author');
        IF userId > 0 THEN
            SELECT `id`,`teaser`,`title`,`uri`,`nextData`.`published`(`dtPublish`) AS pubDate
                FROM `nextData`.`articles` WHERE `idAuthor` = userId ORDER BY `id` DESC LIMIT 20;
            SET earliest = 0;
            SELECT MIN(`id`) INTO earliest FROM `nextData`.`articles` WHERE `idAuthor` = userId;
            SET @mvp_template = 'MyArticles';
            IF `nextData`.`getConfig`('Site','authorSelfPublish') = 'Yes' THEN
                SET canPublish = 'Y';
            END IF;
            CALL `adminMenu`();
        ELSE
            SET @mvp_template = 'Login';
            SET @err = 'Please log in with Editor or Author access.';
            REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
                VALUES (@mvp_session, @mvp_remoteip, 'Articles');
        END IF;
    END IF;
END $$

DROP PROCEDURE IF EXISTS `moreArticles` $$
CREATE PROCEDURE `moreArticles` (IN top BIGINT)
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    IF userId > 0 THEN
        SELECT `id`,`teaser`,`title`,`uri`,`nextData`.`published`(`dtPublish`) AS pubDate
            FROM `nextData`.`articles` WHERE `id` < top ORDER BY `id` DESC LIMIT 20;
        SET @mvp_layout = '';
    ELSE
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author');
        IF userId > 0 THEN
            SELECT `id`,`teaser`,`title`,`uri`,`nextData`.`published`(`dtPublish`) AS pubDate
                FROM `nextData`.`articles` WHERE `id` < top AND `idAuthor` = userId
                ORDER BY `id` DESC LIMIT 20;
        ELSE
            SET @err = 'Please log in with Editor or Author access.';
        END IF;
    END IF;
END $$

DROP PROCEDURE IF EXISTS `ArticleEditor` $$
CREATE PROCEDURE `ArticleEditor` (INOUT articleId BIGINT, IN contentin text, 
                                  IN titlein varchar(256), IN uriin varchar(256),
                                  IN catId BIGINT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    IF userId > 0 THEN
        IF articleId IS NULL OR articleId = 0 THEN
            INSERT INTO `nextData`.`articles` (`idAuthor`) VALUES (userId);
            SET articleId = LAST_INSERT_ID();
        ELSE
            IF contentin IS NOT NULL AND contentin != '' THEN
                UPDATE `nextData`.`articles` SET
                    `content` = `nextData`.`descript`(contentin),
                    `teaser` = `nextData`.`tease`(contentin),
                    `teasePic` = `nextData`.`getTeasePic`(contentin),
                    `title` = `nextData`.`descript`(titlein),
                    `uri` = `nextData`.`urize`(uriin),
                    `idCategory` = catId
                WHERE `id` = articleId;
                SET chk = `nextData`.`resetArticleCategories`(articleId);
                SET @err = `nextData`.`checkDuplicateUri`(articleId, `nextData`.`urize`(uriin));
            END IF;
        END IF;
        SELECT * FROM `nextData`.`articles` WHERE `id` = articleId;
        SELECT *, `nextData`.`catIndent`(`idParent`) AS indent 
            FROM `nextData`.`categories` WHERE `id` > 1 AND `ord` > 0 ORDER BY `ord`;
        SET @mvp_layout = 'popup';
    ELSE
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author');
        IF articleId IS NOT NULL AND articleId > 0 THEN
            SELECT `idAuthor` INTO chk FROM `nextData`.`articles` 
                WHERE `id` = articleId LIMIT 1;
        ELSE
            SET chk = userId;
        END IF;
    
        IF userId > 0 AND userId = chk THEN
            IF articleId IS NULL OR articleId = 0 THEN
                INSERT INTO `nextData`.`articles` (`idAuthor`) VALUES (userId);
                SET articleId = LAST_INSERT_ID();
            ELSE
                IF contentin IS NOT NULL AND contentin != '' THEN
                    UPDATE `nextData`.`articles` SET
                        `content` = `nextData`.`descript`(contentin),
                        `teaser` = `nextData`.`tease`(contentin),
                        `teasePic` = `nextData`.`getTeasePic`(contentin),
                        `title` = `nextData`.`descript`(titlein),
                        `uri` = `nextData`.`urize`(uriin),
                        `idCategory` = catId
                    WHERE `id` = articleId;
                    SET chk = `nextData`.`resetArticleCategories`(articleId);
                END IF;
            END IF;
            SELECT * FROM `nextData`.`articles` WHERE `id` = articleId;
            SELECT *, `nextData`.`catIndent`(`idParent`) AS indent 
                FROM `nextData`.`categories` WHERE `id` > 1 AND `ord` > 0 ORDER BY `ord`;
            SET @mvp_layout = 'popup';
        ELSE
            SET @mvp_template = 'Login';
            SET @err = 'Please log in with Editor or Author access.';
            REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
                VALUES (@mvp_session, @mvp_remoteip, 
                    CONCAT('ArticleEditor?articleId=', articleId));
        END IF;
    END IF;
END $$

DROP PROCEDURE IF EXISTS `publishArticle` $$
CREATE PROCEDURE `publishArticle` (IN articleId BIGINT, IN invRev TINYINT,
                                   OUT notificationsSent INT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    DECLARE pubDate DATETIME DEFAULT NULL;
    SET notificationsSent = 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    IF userId = 0 THEN
        SELECT `idAuthor` INTO chk FROM `nextData`.`articles` 
            WHERE `id` = articleId LIMIT 1;
        IF chk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author')
            AND `nextData`.`getConfig`('Site','authorSelfPublish') = 'Yes' THEN
            SET userId = chk;
        END IF;
    END IF;
    
    IF userId > 0 THEN
        IF invRev = 1 THEN
            SELECT `dtPublish`,`alreadyPublished` INTO pubDate, chk 
                FROM `nextData`.`articles` WHERE `id` = articleId LIMIT 1;
            IF pubDate IS NULL THEN
                UPDATE `nextData`.`articles` 
                    SET `dtPublish` = NOW(), `alreadyPublished` = 1
                    WHERE `id` = articleId;
            END IF;
            IF pubDate IS NULL AND chk = 0 THEN
                SET notificationsSent = 
                    `nextData`.`notifyNewArticle`(articleId, `nextData`.`getHost`(@mvp_headers));
            END IF;
        ELSE
            UPDATE `nextData`.`articles` SET `dtPublish` = NULL WHERE `id` = articleId;
        END IF;
    ELSE
        SET @err = 'Please log in with Editor access or allow Author Self-Publishing.';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `ArticleTags` $$
CREATE PROCEDURE `ArticleTags` (INOUT articleId BIGINT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    IF userId = 0 THEN
        SELECT `idAuthor` INTO chk FROM `nextData`.`articles` 
            WHERE `id` = articleId LIMIT 1;
        IF chk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author') THEN
            SET userId = chk;
        END IF;
    END IF;
    
    IF userId > 0 THEN
        SELECT `tags`.`id`, `tags`.`uri`, `tags`.`displayName`, `article_tags`.`idArticle`
        FROM `nextData`.`tags` LEFT JOIN `nextData`.`article_tags` 
            ON `tags`.`id` = `article_tags`.`idTag` 
            AND `article_tags`.`idArticle` = articleId
        ORDER BY `tags`.`displayName` ASC;
        SET @mvp_layout = 'popup';
    ELSE
        SET @err = 'Please log in with Editor or Author access.';
        SET @mvp_template = 'Login';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `addDropTag` $$
CREATE PROCEDURE `addDropTag` (IN articleId BIGINT, IN tagId BIGINT, IN invRev TINYINT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    IF userId = 0 THEN
        SELECT `idAuthor` INTO chk FROM `nextData`.`articles` 
            WHERE `id` = articleId LIMIT 1;
        IF chk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author') THEN
            SET userId = chk;
        END IF;
    END IF;
    
    IF userId > 0 THEN
        IF invRev = 1 THEN
            REPLACE INTO `nextData`.`article_tags` (`idArticle`,`idTag`)
                VALUES (articleId, tagId);
        ELSE
            DELETE FROM `nextData`.`article_tags`
                WHERE `idArticle` = articleId AND `idTag` = tagId;
        END IF;
    ELSE
        SET @err = 'Please log in with Editor or Author access.';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `NewTag` $$
CREATE PROCEDURE `NewTag` (INOUT articleId BIGINT, IN tagName VARCHAR(1024), 
                           IN tagUri VARCHAR(1024))
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    IF userId = 0 THEN
        SELECT `idAuthor` INTO chk FROM `nextData`.`articles` 
            WHERE `id` = articleId LIMIT 1;
        IF chk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author') THEN
            SET userId = chk;
        END IF;
    END IF;
    
    IF userId > 0 THEN
        INSERT INTO `nextData`.`tags` (`uri`, `displayName`)
            VALUES (`nextData`.`urize`(tagUri), `nextData`.`descript`(tagName));
        SET chk = LAST_INSERT_ID();
        INSERT INTO `nextData`.`article_tags` (`idTag`,`idArticle`)
            VALUES (chk, articleId);
        CALL `ArticleTags`(articleId);
        SET @mvp_template = 'ArticleTags';
    ELSE
        SET @err = 'Please log in with Editor or Author access.';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Categories` $$
CREATE PROCEDURE `Categories` ()
BEGIN
    DECLARE userId, tmpord BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SELECT * FROM `nextData`.`categories` WHERE `id` > 1 AND `ord` > 0 ORDER BY `ord`;
        CALL `adminMenu`();
    ELSE
        SET @err = 'Please log in with Admin privileges.';
        SET @mvp_template = 'Login';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Categories');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `UpdateCategories` $$
CREATE PROCEDURE `UpdateCategories` (IN htmlCategories TEXT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SET chk = `nextData`.`categoryHtmlParse`(htmlCategories);
        IF chk > 0 THEN
            SET chk = `nextData`.`resetArticleCategories`(NULL);
            SET chk = `nextData`.`setConfig`('Site','mainMenu',
                `nextData`.`publicCategoriesHtml`());
        END IF;
        SELECT * FROM `nextData`.`categories` WHERE `id` > 1 AND `ord` > 0 ORDER BY `ord`;
        SET @mvp_template = 'Categories';
        SET @err = 'Categories Successfully Updated';
        CALL `adminMenu`();
    ELSE
        SET @err = 'Please log in with Admin privileges.';
        SET @mvp_template = 'Login';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Categories');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `MailErrors` $$
CREATE PROCEDURE `MailErrors` ()
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SELECT *, DATE_FORMAT(`theDate`,'%b %D, %Y %h:%i %p') AS formatDate 
            FROM `nextData`.`mail_errors`;
        CALL `adminMenu`();
    ELSE
        SET @err = 'Please log in with Admin privileges.';
        SET @mvp_template = 'Login';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'MailErrors');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `ClearMailErrors` $$
CREATE PROCEDURE `ClearMailErrors` ()
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        DELETE FROM `nextData`.`mail_errors`;
        SET @mvp_template = 'MailErrors';
        CALL `adminMenu`();
    ELSE
        SET @err = 'Please log in with Admin privileges.';
        SET @mvp_template = 'Login';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'MailErrors');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `WPImport` $$
CREATE PROCEDURE `WPImport` (IN xmlFile VARCHAR(1024), OUT messg VARCHAR(48))
BEGIN
    DECLARE xml, parseText, itemXML, itemType, parseItem, itemItem TEXT DEFAULT '';
    DECLARE baseURL, blogURL, linkURL VARCHAR(1024) DEFAULT '';
    DECLARE pid, xid, yid, zid, rid, tid BIGINT DEFAULT 0;

IF xmlFile IS NOT NULL AND xmlFile != '' THEN
IF `nextData`.`checkSession`(@mvp_session,@mvp_remoteip,'Admin') > 0 THEN
    SET xml = np_loadfile(xmlFile);
    SET baseURL = ExtractValue(xml, '//wp:base_site_url');
    SET blogURL = ExtractValue(xml, '//wp:base_blog_url');

    SELECT `id` INTO yid FROM `nextData`.`roles` WHERE `label` = 'Author';
    SET parseText = SUBSTR(xml, LOCATE('<wp:author>', xml));
    WHILE LOCATE('</wp:author>', parseText) > 0 DO
        SET xid = 0;
        SET itemXML = SUBSTR(parseText, 1, LOCATE('</wp:author>', parseText) + 12);
        SELECT COUNT(`id`) INTO xid FROM `nextData`.`users` 
            WHERE `email` = ExtractValue(itemXML, '//wp:author_email');
        IF xid = 0 THEN
            INSERT INTO `nextData`.`users`(`displayName`,`email`,`url`,`avatarUri`)
            VALUES (
                ExtractValue(itemXML, '//wp:author_display_name'),
                ExtractValue(itemXML, '//wp:author_email'),
                ExtractValue(itemXML, '//wp:author_url'),
                ExtractValue(itemXML, '//wp:author_avatar')
            );
            SET zid = LAST_INSERT_ID();
            INSERT INTO `nextData`.`user_roles` (`idUser`,`idRole`) VALUES (zid, yid);
        END IF;
        SET parseText = SUBSTR(parseText,LOCATE('</wp:author>',parseText) + 12);
    END WHILE;
    
    SET parseText = SUBSTR(xml, LOCATE('<wp:category>', xml));
    WHILE LOCATE('</wp:category>', parseText) > 0 DO
        SET xid = 1;
        SET itemXML = SUBSTR(parseText, 1, LOCATE('</wp:category>', parseText) + 14);
        SELECT `id` INTO xid FROM `nextData`.`categories`
            WHERE `uri` = ExtractValue(itemXML, '//wp:category_parent')
            LIMIT 1;
        SELECT COUNT(`id`) INTO yid FROM `nextData`.`categories` 
            WHERE `uri` = ExtractValue(itemXML, '//wp:category_nicename');
        
        IF yid = 0 AND 
        ExtractValue(itemXML, '//wp:category_nicename') != 'uncategorized' THEN
            SELECT MAX(`ord`) INTO zid FROM `nextData`.`categories`;
            INSERT INTO `nextData`.`categories`
                (`idParent`,`displayName`,`uri`,`ord`) VALUES (
                    xid,
                    ExtractValue(itemXML, '//wp:cat_name'),
                    ExtractValue(itemXML, '//wp:category_nicename'),
                    zid + 1
                );
        END IF;
                
        SET parseText = SUBSTR(parseText,LOCATE('</wp:category>',parseText)+14);
    END WHILE;
    
    SET parseText = SUBSTR(xml, LOCATE('<wp:tag>', xml));
    WHILE LOCATE('</wp:tag>', parseText) > 0 DO
        SET itemXML = SUBSTR(parseText, 1, LOCATE('</wp:tag>', parseText) + 9);
        SELECT COUNT(`uri`) INTO xid FROM `nextData`.`tags`
            WHERE `uri` = ExtractValue(itemXML, '//wp:tag_slug');
        IF xid = 0 THEN
            INSERT INTO `nextData`.`tags` (`displayName`, `uri`) VALUES (
                    ExtractValue(itemXML, '//wp:tag_name'),
                    ExtractValue(itemXML, '//wp:tag_slug')
                );
        END IF;
                
        SET parseText = SUBSTR(parseText, LOCATE('</wp:tag>', parseText) + 9);
    END WHILE;
    
    SET parseText = SUBSTR(xml, LOCATE('<item>', xml));
    WHILE LOCATE('</item>', parseText) > 0 DO
        SET itemXML = SUBSTR(parseText, 1, LOCATE('</item>', parseText) + 7);
        SET itemType = ExtractValue(itemXML, '//wp:post_type');
        IF itemType = 'post' OR itemType = 'page' THEN
        SET zid = 0;
        SELECT `id` INTO zid FROM `nextData`.`articles`
            WHERE `uri` = ExtractValue(itemXML, '//wp:post_name') LIMIT 1;
        IF zid > 0 THEN
            SET xid = 0;
            SELECT `id` INTO xid FROM `nextData`.`users`
                WHERE `displayName` = 
                    ExtractValue(itemXML, '//dc:creator')
                LIMIT 1;
            INSERT INTO `nextData`.`articles` (`idAuthor`,`content`,`teaser`,
                `title`,`uri`,`dtPublish`,`alreadyPublished`,`numViews`,`idwp`)
                VALUES (xid, ExtractValue(itemXML, '//content:encoded'),
                `nextData`.`tease`(ExtractValue(itemXML,'//content:encoded')),
                ExtractValue(itemXML, '//title'),
                ExtractValue(itemXML, '//wp:post_name'),
                ExtractValue(itemXML, '//wp:post_date'),    1, 0,
                ExtractValue(itemXML, '//wp:post_id'));
            SET xid = LAST_INSERT_ID();
            
            SET parseItem = SUBSTR(itemXML, LOCATE('<category', itemXML));
            WHILE LOCATE('</category>', parseItem) > 0 DO
                SET itemItem = SUBSTR(parseItem, 1, LOCATE('</category>', parseItem) + 11);
                SET yid = 0;
                SET itemType = ExtractValue(itemItem, '//@domain');
                IF itemType = 'category' THEN
                    SELECT `id` INTO yid FROM `nextData`.`categories`
                        WHERE `uri` = ExtractValue(itemItem, '//@nicename') 
                        LIMIT 1;
                    IF yid > 0 THEN
                        UPDATE `nextData`.`articles` SET `idCategory` = yid
                            WHERE `id` = xid;
                    END IF;
                ELSE
                    SELECT `id` INTO yid FROM `nextData`.`tags`
                        WHERE `uri` = ExtractValue(itemItem, '//@nicename') 
                        LIMIT 1;
                    IF yid > 0 THEN
                        INSERT INTO `nextData`.`article_tags`
                            (`idArticle`, `idTag`) VALUES (xid, yid);
                    END IF;
                END IF;
                
                SET parseItem = 
                    SUBSTR(parseItem, LOCATE('</category>', parseItem) + 11);
            END WHILE;
        END IF;
        END IF;
        
        SET parseText = SUBSTR(parseText, LOCATE('</item>', parseText) + 7);
    END WHILE;
    
    SET rid = `nextData`.`resetArticleCategories`(NULL);
    SET messg = 'Import Successful';
ELSE
  SET @err = 'Please log in with Admin privileges';
END IF;
END IF;

    CALL `adminMenu`();
END $$

DELIMITER ;


-- 
--  NextPress Core Admin (SSL) Procedures
--  Copyright (C) 2016 Lowadobe Web Services, LLC 
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

DROP PROCEDURE IF EXISTS `Register` $$
CREATE PROCEDURE `Register`(IN addr VARCHAR(256))
BEGIN
    DECLARE idUsr, retVal INT DEFAULT 0;
    DECLARE vhash VARCHAR(32);
    SELECT `id` INTO idUsr FROM `nextData`.`users`
        WHERE `email` = addr LIMIT 1;
    IF idUsr > 0 THEN
        SET @err = CONCAT('The email address ',addr,' is already linked to an account.');
        SET @mvp_template = 'Login';
    ELSE
        IF is_email(addr) = 0 THEN
            SET vhash = MD5(CONCAT(@mvp_remoteip, RAND()));
            INSERT INTO `nextData`.`users` (`email`, `verifyCode`)
                VALUES (addr, vhash);
            SET idUsr = LAST_INSERT_ID();
            SET retVal = `nextData`.`sendmail`(addr, 0, vhash, 'register');
            IF retVal != 0 THEN
                SET @err = CONCAT('Problem sending email (', retVal, ')');
                DELETE FROM `nextData`.`users` WHERE `id` = idUsr;
                SET @mvp_template = 'Login';
            END IF;
        ELSE
            SET @err = CONCAT('The email address ',addr,' did not pass validation test.');
            SET @mvp_template = 'Login';
        END IF;
    END IF;
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
        SELECT * FROM `nextData`.`pages` ORDER BY `uri`,`mobile`;
        CALL `adminMenu`();
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Pages');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `PageEditor` $$
CREATE PROCEDURE `PageEditor` (INOUT pageUri VARCHAR(512), INOUT pageTpl VARCHAR(1024),
                               INOUT pageMobile TINYINT, INOUT pageContent TEXT,
                               OUT pagePub TINYINT)
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        IF pageContent IS NOT NULL AND TRIM(pageContent) != '' THEN
            IF pageTpl IS NULL OR pageTpl = '' THEN
                SET pageTpl = `nextData`.`urize`(REPLACE(pageUri,'/',''));
            END IF;
            IF pageMobile IS NULL THEN
                SET pageMobile = 0;
            END IF;
            REPLACE INTO `nextData`.`pages` (`uri`,`tpl`,`mobile`,`content`)
                VALUES (`nextData`.`urize`(pageUri), pageTpl, pageMobile, pageContent);
        END IF;
        SELECT `uri`,`tpl`,`mobile`,`published`,`content`
            INTO pageUri, pageTpl, pageMobile, pagePub, pageContent
            FROM `nextData`.`pages` 
            WHERE `uri` = pageUri AND `mobile` = pageMobile LIMIT 1;
        SET @mvp_layout = 'popup';
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 
                CONCAT('PageEditor?pageUri=',pageUri,'&pageMobile=',pageMobile));
    END IF;
END $$

DROP PROCEDURE IF EXISTS `publishPage` $$
CREATE PROCEDURE `publishPage` (IN pageUri VARCHAR(512), IN pageMobile TINYINT,
                                IN invRev TINYINT)
BEGIN
    DECLARE userId, chk, notificationsSent BIGINT DEFAULT 0;
    DECLARE pubDate DATETIME DEFAULT NULL;
    SET notificationsSent = 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    
    IF userId > 0 THEN
        IF invRev = 1 THEN
            SET @err = `nextData`.`publishPage`(pageUri,pageMobile);
        ELSE
            SET @err = `nextData`.`removePage`(pageTpl,pageMobile);
        END IF;
        SET chk = `nextData`.`findActiveDropins`();
    ELSE
        SET @err = 'Please log in with Admin privileges';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Dropins` $$
CREATE PROCEDURE `Dropins` ()
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SELECT `id`, `img` FROM `nextData`.`dropins` ORDER BY `id`;
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Pages');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Media` $$
CREATE PROCEDURE `Media` ()
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId = 0 THEN
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    END IF;
    IF userId > 0 THEN
        SELECT `media`.*, `nextData`.`published`(`dtAdded`) AS addedDate, 
               `users`.`displayName`, `users`.`email` 
            FROM `nextData`.`media`
            JOIN `nextData`.`users` ON `media`.`idAuthor` = `users`.`id`
            ORDER BY `dtAdded` DESC;
        CALL `adminMenu`();
    ELSE
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author');
        IF userId > 0 THEN
            SELECT `media`.*, `nextData`.`published`(`dtAdded`) AS addedDate
                FROM `nextData`.`media` WHERE `idAuthor` = userId
                ORDER BY `dtAdded` DESC;
            CALL `adminMenu`();
            SET @mvp_template = 'MyMedia';
        ELSE
            SET @mvp_template = 'Login';
            SET @err = 'Please log in with Admin, Editor, or Author privileges';
            REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
                VALUES (@mvp_session, @mvp_remoteip, 'Media');
        END IF;
    END IF;
END $$

DROP PROCEDURE IF EXISTS `addMedia` $$
CREATE PROCEDURE `addMedia` (IN upload VARCHAR(1024), IN fname VARCHAR(1024),
                             OUT newId BIGINT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    DECLARE nUri, tUri VARCHAR(1024) DEFAULT '';
    SET newId = 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId = 0 THEN
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    END IF;
    IF userId = 0 THEN
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Author');
    END IF;
    IF userId > 0 THEN
        IF upload IS NOT NULL AND upload != '' AND fname IS NOT NULL AND fname != '' THEN
            SET fname = `nextData`.`filesafe`(fname);
            IF `nextData`.`isImage`(upload) THEN
                SET nUri = CONCAT('/media/images/', fname);
                SET chk = convert_img(
                    upload,
                    CONCAT(`nextData`.`getConfig`('Site','webroot'), nUri),
                    `nextData`.`getConfig`('Media','mediaResize')
                    );
                IF chk != 0 THEN
                    SET @err = CONCAT('Error processing image file: ',chk);
                ELSE
                    SET tUri = CONCAT('/media/images/thumb_', fname);
                    SET chk = convert_img(
                        upload,
                        CONCAT(`nextData`.`getConfig`('Site','webroot'), tUri),
                        `nextData`.`getConfig`('Media','mediaThumbsize')
                        );
                    IF chk != 0 THEN
                        SET tUri = NULL;
                    END IF;
                    INSERT INTO `nextData`.`media` 
                        (`idAuthor`,`uri`,`thumb`,`isImage`,`dtAdded`)
                        VALUES (userId, nUri, tUri, 1, NOW());
                    SET newId = LAST_INSERT_ID();
                END IF;
            ELSE
                SET nUri = CONCAT('/media/files/', fname);
                SET chk = file_copy(upload,
                        CONCAT(`nextData`.`getConfig`('Site','webroot'), nUri));
                IF chk != 0 THEN
                    SET @err = CONCAT('Error processing media file: ',chk);
                ELSE
                    INSERT INTO `nextData`.`media` 
                        (`idAuthor`,`uri`,`thumb`,`isImage`,`dtAdded`)
                    VALUES 
                        (userId, nUri, '/media/images/file_thumb.png', 0, NOW());
                    SET newId = LAST_INSERT_ID();
                END IF;
            END IF;
        END IF;
        IF newId > 0 THEN
            SELECT * FROM `nextData`.`media` WHERE `id` = newId;
        END IF;
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Admin, Editor or Author privileges';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'AddMedia');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `deleteMedia` $$
CREATE PROCEDURE `deleteMedia` (IN mid BIGINT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    DECLARE filepath VARCHAR(1024);
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId = 0 THEN
        SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Editor');
    END IF;
    IF userId > 0 THEN
        SELECT `uri` INTO filepath FROM `nextData`.`media` WHERE `id` = mid LIMIT 1;
        SET filepath = CONCAT(`nextData`.`getConfig`('Site','webroot'), filepath);
        SET chk = file_delete(filepath);
        IF chk = 0 THEN
            DELETE FROM `nextData`.`media` WHERE `id` = mid;
        ELSE
            SET @err = CONCAT('Error processing file (',chk,')');
        END IF;
    ELSE
        SET @err = 'Please log in with Admin or Editor privileges';
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
        SELECT * FROM `nextData`.`config` ORDER BY `ord`;
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
        SET @err = `nextData`.`setConfig`(pid, cid, cval);
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
                                  IN catId BIGINT, OUT catSelect TEXT)
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
            END IF;
        END IF;
        SELECT * FROM `nextData`.`articles` WHERE `id` = articleId;
        SET catSelect = `nextData`.`categorySelector`(articleId);
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
            SET catSelect = `nextData`.`catSelector`(articleId);
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
                SET notificationsSent = `nextData`.`notifyNewArticle`(articleId);
            END IF;
        ELSE
            UPDATE `nextData`.`articles` SET `dtPublish` = NULL WHERE `id` = articleId;
        END IF;
    ELSE
        SET @err = 'Please log in with Editor access or allow Author Self-Publishing.';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `ArticleTags` $$
CREATE PROCEDURE `ArticleTags` (INOUT articleId BIGINT, OUT artTitle VARCHAR(256))
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
        SELECT `title` INTO artTitle FROM `nextData`.`articles` WHERE `id` = articleId;
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
                           IN tagUri VARCHAR(1024), OUT artTitle VARCHAR(256))
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
        CALL `ArticleTags`(articleId, artTitle);
        SET @mvp_template = 'ArticleTags';
    ELSE
        SET @err = 'Please log in with Editor or Author access.';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `Categories` $$
CREATE PROCEDURE `Categories` (OUT htmlCategories TEXT)
BEGIN
    DECLARE userId, tmpord BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SET htmlCategories = `nextData`.`categoriesHtml`();
        CALL `adminMenu`();
    ELSE
        SET @err = 'Please log in with Admin privileges.';
        SET @mvp_template = 'Login';
        REPLACE INTO `nextData`.`sessions` (`id`,`ipAddress`,`redirect`)
            VALUES (@mvp_session, @mvp_remoteip, 'Categories');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `UpdateCategories` $$
CREATE PROCEDURE `UpdateCategories` (INOUT htmlCategories TEXT)
BEGIN
    DECLARE userId, chk BIGINT DEFAULT 0;
    SET userId = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Admin');
    IF userId > 0 THEN
        SET chk = `nextData`.`categoryHtmlParse`(htmlCategories);
        IF chk > 0 THEN
            SET chk = `nextData`.`resetArticleCategories`(NULL);
        END IF;
        -- Here we cache the Categories dropin for speed
        SET htmlCategories = `nextData`.`publicCategories`();
        SET chk = file_write(CONCAT(`nextData`.`getConfig`('Site','tplroot'),
                             '/public/dropins/Categories.tpl'),htmlCategories);
        IF chk = 0 THEN
            SET chk = `reload_apache`();
        END IF;
        
        SET htmlCategories = `nextData`.`categoriesHtml`();
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

DROP PROCEDURE IF EXISTS `ModerateComments` $$
CREATE PROCEDURE `ModerateComments` (IN spm INT, IN appr INT)
BEGIN
    DECLARE schk INT DEFAULT 0;
    SET schk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Moderator');
    IF schk > 0 THEN
        IF spm IS NULL THEN SET spm = 0; END IF;
        IF appr IS NULL THEN SET appr = 0; END IF;
        SELECT `comments`.*,
            `users`.`displayName`, `users`.`avatarUri`,
            `articles`.`title` AS arTitle, `articles`.`uri` AS arUri, `articles`.`dtPublish` AS dtArticle,
            SUM(`comment_votes`.`voteVal`) AS voteTotal, COUNT(`comment_votes`.`idUser`) AS voteCount,
            parent.`dtComment` AS dtParent, parent.`content` AS pcontent,
            puser.`displayName` AS pCommenter, puser.`avatarUri` AS pAvatar
        FROM `nextData`.`comments`
            JOIN `nextData`.`users` ON `comments`.`idCommenter` = `users`.`id`
            JOIN `nextData`.`articles` ON `comments`.`idArticle` = `articles`.`id`
            LEFT JOIN `nextData`.`comment_votes` ON `comments`.`id` = `comment_votes`.`idComment`
            LEFT JOIN `nextData`.`comments` parent ON `comments`.`idParent` = parent.`id`
            LEFT JOIN `nextData`.`users` puser ON parent.`idCommenter` = puser.`id`
        WHERE `comments`.`approved` = appr AND `comments`.`spam` = spm
            GROUP BY `comments`.`id` ORDER BY `comments`.`id`;
        CALL `adminMenu`();
    ELSE
        SET @mvp_template = 'Login';
        SET @err = 'Please log in with Moderator privileges';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `deleteComment` $$
CREATE PROCEDURE `deleteComment` (IN idComment BIGINT)
BEGIN
    DECLARE schk, replyCount INT DEFAULT 0;
    SET schk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Moderator');
    IF schk > 0 THEN
        SELECT COUNT(`id`) INTO replyCount FROM `nextData`.`comments` WHERE `idParent` = idComment;
        IF replyCount > 0 THEN
            UPDATE `nextData`.`comments` SET `content` = '&lt; &lt; Comment Deleted &gt; &gt;' WHERE `id` = idComment;
        ELSE
            DELETE FROM `nextData`.`comments` WHERE `id` = idComment;
        END IF;
    ELSE
        SET @err = 'Please log in with Moderator privileges';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `markSpam` $$
CREATE PROCEDURE `markSpam` (IN idComment BIGINT)
BEGIN
    DECLARE schk INT DEFAULT 0;
    SET schk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Moderator');
    IF schk > 0 THEN
        UPDATE `nextData`.`comments` SET `spam` = 1, `approved` = 0 WHERE `id` = idComment;
    ELSE
        SET @err = 'Please log in with Moderator privileges';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `approveComment` $$
CREATE PROCEDURE `approveComment` (IN idComment BIGINT)
BEGIN
    DECLARE schk INT DEFAULT 0;
    SET schk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Moderator');
    IF schk > 0 THEN
        UPDATE `nextData`.`comments` SET `spam` = 0, `approved` = 1 WHERE `id` = idComment;
    ELSE
        SET @err = 'Please log in with Moderator privileges';
    END IF;
END $$

DROP PROCEDURE IF EXISTS `voteComment` $$
CREATE PROCEDURE `voteComment` (IN cid BIGINT, IN vote INT)
BEGIN
    DECLARE schk, guestVotes, guestVoter INT DEFAULT 0;
    IF TRIM(LOWER(`nextData`.`getConfig`('Comments','voting'))) = 'yes' THEN
        IF vote IS NULL OR vote > 0 THEN
            SET vote = 1;
        ELSEIF vote < 0 THEN
            SET vote = -1;
        END IF;
        SET schk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Commenter');
        IF schk > 0 THEN
            REPLACE INTO `nextData`.`comment_votes` (`idComment`, `idUser`, `voteVal`) VALUES (cid, schk, vote);
        ELSEIF TRIM(LOWER(`nextData`.`getConfig`('Comments','votingLogin'))) = 'no' THEN
            SET guestVoter = `nextData`.`getConfig`('Comments','guestUserId');
            SELECT `voteVal` INTO guestVotes FROM `nextData`.`comment_votes` WHERE `idComment` = cid AND `idUser` = guestVoter;
            SET vote = guestVotes + vote;
            REPLACE INTO `nextData`.`comment_votes` (`idComment`, `idUser`, `voteVal`) VALUES (cid, guestVoter, vote);
        END IF;
    END IF;
END $$

-- This one is "admin" because it checks the https session cookie
DROP PROCEDURE IF EXISTS `getComments` $$
CREATE PROCEDURE `getComments` (IN articleId INT, IN top BIGINT, OUT total INT, OUT earliest VARCHAR(32),
                                OUT loggedIn INT, OUT cmntrName VARCHAR(1024), OUT cmntrAvatar VARCHAR(1024),
                                OUT moderator INT, OUT showAvatars INT)
BEGIN
END $$

DROP PROCEDURE IF EXISTS `SubmitComment` $$
CREATE PROCEDURE `SubmitComment` (IN articleId INT, IN replyId BIGINT, IN eaddr VARCHAR(1024), IN pass VARCHAR(1024),
                                  IN commentText TEXT, IN nReply INT, IN nThread INT, IN nDigest INT)
BEGIN
    DECLARE schk, appr, spm, closeDays INT DEFAULT 0;
    DECLARE tid, cid BIGINT DEFAULT 0;
    DECLARE pubDate DATETIME;
    
    SET closeDays = TRIM(LOWER(`nextData`.`getConfig`('Comments','closeAfter')));
    SELECT `dtPublish` INTO pubDate FROM `nextData`.`articles` WHERE `id` = articleId LIMIT 1;
    IF pubDate IS NULL OR (closeDays > 0 AND DATE_ADD(pubDate, INTERVAL closeDays DAY) < UTC_TIMESTAMP()) THEN
        SET @err = 'Comments are closed for this article';
    ELSE
        IF eaddr IS NOT NULL AND eaddr != '' AND pass IS NOT NULL AND pass != '' THEN
            SELECT `idUser` INTO schk FROM `nextData`.`users` WHERE `email` = eaddr AND `password` = SHA2(pass, 512) LIMIT 1;
            IF schk > 0 THEN
                REPLACE INTO `nextData`.`sessions` (`id`,`idUser`,`ipAddress`) VALUES (@mvp_session, schk, @mvp_remoteip);
            ELSE
                SET @err = 'Unrecognized Login Credentials... ';
            END IF;
        END IF;
        -- checkSession is done outside of Login
        SET schk = `nextData`.`checkSession`(@mvp_session, @mvp_remoteip, 'Commenter');
    
        IF schk > 0 OR TRIM(LOWER(`nextData`.`getConfig`('Comments','loginOnly'))) = 'no' THEN
            -- Who is posting?
            IF schk = 0 THEN -- Guest Commenter
                SET schk = `nextData`.`getConfig`('Comments','guestUserId');
            ELSE
                IF TRIM(LOWER(`nextData`.`getConfig`('Comments','modPrevApproved'))) = 'yes' THEN
                    SELECT COUNT(`id`) INTO appr FROM `nextData`.`comments` WHERE `idCommenter` = schk AND `approved` > 0;
                END IF;
            END IF;
            SELECT CONCAT(@err, 'Posted as ', `displayName`) INTO @err
                FROM `nextData`.`users` WHERE `id` = schk LIMIT 1;

            -- Set parent id and top level id
            IF replyId IS NOT NULL AND replyId > 0 AND TRIM(LOWER(`nextData`.`getConfig`('Comments','threaded'))) = 'yes' THEN
                -- reply, so get thread starter (idTop)
                SELECT `idTop` INTO tid FROM `nextData`.`comments` WHERE `id` = replyId LIMIT 1;
                IF tid = 0 THEN
                    SET tid = replyId;
                END IF;
            ELSE
                SET replyId = 0;
            END IF;
            
            IF TRIM(LOWER(`nextData`.`getConfig`('Comments','modAll'))) = 'yes' THEN
                SET appr = 0;
            ELSE
                -- Spam Blacklist?
                SET spm = `nextData`.`applyBlacklist`(commentText, `nextData`.`getConfig`('Comments', 'blacklist'));
                IF appr = 0 AND spm = 0 THEN
                    -- Hold Blacklist?
                    SET appr = 1 - `nextData`.`applyBlacklist`(commentText, `nextData`.`getConfig`('Comments', 'modlist'));
                    IF appr = 0 THEN
                        -- And finally, too many links?
                        SET appr = `nextData`.`linkFilter`(commentText, `nextData`.`getConfig`('Comments', 'modlistNumlinks'));
                    END IF;
                END IF;
            END IF;

            INSERT INTO `nextData`.`comments` (`idArticle`,`idCommenter`,`idParent`,`idTop`,`dtComment`,`content`,`tease`,`approved`,`spam`)
                VALUES (articleId, schk, replyId, tid, UTC_TIMESTAMP(), `nextData`.`descript`(commentText), `nextData`.`teaseComment`(commentText), appr, spm);
            SET cid = LAST_INSERT_ID();
            
            -- And perform notifications after the insert is completed 
            -- this way the Akismet plugin can run off its trigger first
            SET schk = `nextData`.`commentNotifications`(cid);
        ELSE
            SET @err = CONCAT(@err, 'You must login to submit comments');
        END IF;
    END IF;
END $$

DROP PROCEDURE IF EXISTS `WPImport` $$
CREATE PROCEDURE `WPImport` (IN xmlFile VARCHAR(1024), OUT messg VARCHAR(48))
BEGIN
    DECLARE xml, parseText, itemXML, itemType, parseItem TEXT DEFAULT '';
    DECLARE baseURL, blogURL, linkURL VARCHAR(1024) DEFAULT '';
    DECLARE pid, xid, yid, zid, rid, tid BIGINT DEFAULT 0;

IF xmlFile IS NOT NULL AND xmlFile != '' THEN
IF `nextData`.`checkSession`(@mvp_session,@mvp_remoteip,'Admin') > 0 THEN
    SET xml = LOAD_FILE(xmlFile);
    SET xid = `nextData`.`setConfig`('core','tagline',
        CONCAT(ExtractValue(xml, '/rss/channel/title'), ' - ',
            ExtractValue(xml, '/rss/channel/description')));
    SET baseURL = ExtractValue(xml, '//wp:base_site_url');
    SET blogURL = ExtractValue(xml, '//wp:base_blog_url');
    
    SET parseText = xml;
    WHILE LOCATE('</wp:author>', parseText) > 0 DO
        INSERT INTO `nextData`.`users`(`displayName`,`email`,`url`,`avatarUri`)
        VALUES (
            ExtractValue(parseText, '//wp:author_display_name'),
            ExtractValue(parseText, '//wp:author_email'),
            ExtractValue(parseText, '//wp:author_url'),
            ExtractValue(parseText, '//wp:author_avatar')
        );
                
        SET parseText = SUBSTR(parseText,LOCATE('</wp:author>',parseText) + 12);
    END WHILE;
    
    SET parseText = xml;
    WHILE LOCATE('</wp:category>', parseText) > 0 DO
        SET xid = 0;
        SELECT `id` INTO xid FROM `nextData`.`categories`
            WHERE `uri` = ExtractValue(parseText, '//wp:category_parent')
            LIMIT 1;
        
        INSERT INTO `nextData`.`categories`
            (`idParent`,`displayName`,`uri`,`ord`) VALUES (
                xid,
                ExtractValue(parseText, '//wp:cat_name'),
                ExtractValue(parseText, '//wp:category_nicename'),
                ExtractValue(parseText, '//wp:term_id')
            );
                
        SET parseText = SUBSTR(parseText,LOCATE('</wp:category>',parseText)+14);
    END WHILE;
    
    SET parseText = xml;
    WHILE LOCATE('</wp:tag>', parseText) > 0 DO
        INSERT INTO `nextData`.`tags` (`displayName`, `uri`) VALUES (
                ExtractValue(parseText, '//wp:tag_name'),
                ExtractValue(parseText, '//wp:tag_slug')
            );
                
        SET parseText = SUBSTR(parseText, LOCATE('</wp:tag>', parseText) + 9);
    END WHILE;
    
    SELECT `id` INTO rid FROM `roles` WHERE `label` = 'Commenter' LIMIT 1;
    
    SET parseText = xml;
    WHILE LOCATE('</item>', parseText) > 0 DO
        SET itemXML = SUBSTR(parseText, 1, LOCATE('</item>', parseText));
        SET itemType = ExtractValue(itemXML, '//wp:post_type');
        IF itemType = 'attachment' THEN
            SET linkURL = ExtractValue(itemXML, '//guid');
            IF LOCATE(baseURL, linkURL) = 1 THEN
                SET linkURL = SUBSTR(linkURL, LENGTH(baseURL) + 1);
            ELSEIF LOCATE(blogURL, linkURL) = 1 THEN
                SET linkURL = SUBSTR(linkURL, LENGTH(blogURL) + 1);
            END IF;
            INSERT INTO `nextData`.`media` (`uri`, `isImage`)
                VALUES (linkURL, `nextData`.`isImage`(linkURL));
        
        ELSEIF itemType = 'post' OR itemType = 'page' THEN
            SET linkURL = ExtractValue(itemXML, '//link');
            IF LOCATE(baseURL, linkURL) = 1 THEN
                SET linkURL = SUBSTR(linkURL, LENGTH(baseURL) + 1);
            ELSEIF LOCATE(blogURL, linkURL) = 1 THEN
                SET linkURL = SUBSTR(linkURL, LENGTH(blogURL) + 1);
            END IF;
            SET xid = 0;
            SELECT `id` INTO xid FROM `nextData`.`users`
                WHERE `displayName` = 
                    ExtractValue(itemXML, '//dc:creator')
                LIMIT 1;
            INSERT INTO `nextData`.`articles` (`idAuthor`,`content`,`teaser`,
                `title`,`uri`,`dtPublish`,`alreadyPublished`,`numViews`,`idwp`)
                VALUES (xid, ExtractValue(itemXML, '//content:encoded'),
                `nextData`.`tease`(ExtractValue(itemXML,'//content:encoded')),
                ExtractValue(itemXML, '//title'),linkURL,
                ExtractValue(itemXML, '//pubDate'),    1, 0,
                ExtractValue(itemXML, '//wp:post_id'));
            SET xid = LAST_INSERT_ID();
            
            SET parseItem = itemXML;
            WHILE LOCATE('</category>', parseItem) > 0 DO
                SET yid = 0;
                SET itemType = ExtractValue(parseItem, '//@domain');
                IF itemType = 'category' THEN
                    SELECT `id` INTO yid FROM `nextData`.`categories`
                        WHERE `uri` = ExtractValue(parseItem, '//@nicename') 
                        LIMIT 1;
                    IF yid > 0 THEN
                        INSERT INTO `nextData`.`article_categories`
                            (`idArticle`, `idCategory`)    VALUES (xid, yid);
                    END IF;
                ELSE
                    SELECT `id` INTO yid FROM `nextData`.`tags`
                        WHERE `uri` = ExtractValue(parseItem, '//@nicename') 
                        LIMIT 1;
                    IF yid > 0 THEN
                        INSERT INTO `nextData`.`article_tags`
                            (`idArticle`, `idTag`) VALUES (xid, yid);
                    END IF;
                END IF;
                
                SET parseItem = 
                    SUBSTR(parseItem, LOCATE('</category>', parseItem) + 11);
            END WHILE;

            IF rid > 0 THEN
            SET parseItem = itemXML;
            WHILE LOCATE('</wp:comment>', parseItem) > 0 DO
                SET yid = 0;
                SELECT `id` INTO yid FROM `nextData`.`users`
                WHERE `displayName` = 
                    ExtractValue(parseItem,'//wp:comment_author')
                    OR `email` = 
                    ExtractValue(parseItem,'//wp:comment_author_email') LIMIT 1;
                IF yid = 0 THEN
                    INSERT INTO `nextData`.`users`(`displayName`,
                        `email`,`url`) VALUES (
                        ExtractValue(parseItem, '//wp:comment_author'),
                        ExtractValue(parseItem, '//wp:comment_author_email'),
                        ExtractValue(parseItem, '//wp:comment_author_url'));
                    SET yid = LAST_INSERT_ID();
                    INSERT INTO `user_roles`(`idUser`,`idRole`)VALUES(yid,rid);
                END IF;

                SET zid = 0;
                SET tid = 0;
                SET pid = ExtractValue(parseItem, '//wp:comment_parent');
                IF pid > 0 THEN
                    SELECT `id` INTO zid FROM `nextData`.`comments`
                        WHERE `idwp` = pid LIMIT 1;
                    SELECT `idTop` INTO tid FROM `nextData`.`comments`
                        WHERE `id` = zid LIMIT 1;
                    IF tid = 0 THEN
                        SET tid = zid;
                    END IF;
                END IF;
                
                INSERT INTO `nextData`.`comments`(`idArticle`,`idCommenter`,
                    `idParent`,`idTop`,`idwp`,`dtComment`,`content`,`approved`)
                    VALUES (xid, yid, zid, tid,
                    ExtractValue(parseItem, '//wp:comment_id'),
                    ExtractValue(parseItem, '//wp:comment_date_gmt'),
                    ExtractValue(parseItem, '//wp:comment_content'),
                    ExtractValue(parseItem, '//wp:comment_approved'));
                
                SET parseItem = 
                    SUBSTR(parseItem,LOCATE('</wp:comment>', parseItem) + 13);
            END WHILE;
            END IF;
        END IF;
        
        SET parseText = SUBSTR(parseText, LOCATE('</item>', parseText) + 7);
    END WHILE;
    
    SET messg = 'Import Successful';
ELSE
  SET @err = 'Please log in with Admin privileges';
END IF;
END IF;

    CALL `adminMenu`();
END $$

DELIMITER ;


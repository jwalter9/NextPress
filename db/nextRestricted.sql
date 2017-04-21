-- 
--  NextPress Data Definitions, Functions & Procedures
--  No direct access by webserver
--  Copyright (C) 2017 Lowadobe Web Services, LLC 
--  web: http://nextpress.org/
--  email: lowadobe@gmail.com
--

DELIMITER $$

DROP FUNCTION IF EXISTS `checkSession` $$
CREATE FUNCTION `checkSession`(sid VARCHAR(32), ip VARCHAR(128), 
                               rolename VARCHAR(1024)) RETURNS BIGINT
READS SQL DATA
BEGIN
    DECLARE userId BIGINT DEFAULT 0;
    IF rolename IS NOT NULL THEN
        SELECT `sessions`.`idUser` INTO userId FROM `sessions`
        JOIN `users` ON `sessions`.`idUser` = `users`.`id`
        JOIN `user_roles` ON `sessions`.`idUser` = `user_roles`.`idUser`
        JOIN `roles` ON `user_roles`.`idRole` = `roles`.`id`
        WHERE `sessions`.`id` = sid AND `sessions`.`ipAddress` = ip
            AND `users`.`prohibited` = 0 AND `roles`.`label` = rolename LIMIT 1;
    ELSE
        SELECT `sessions`.`idUser` INTO userId FROM `sessions` 
        JOIN `users` ON `sessions`.`idUser` = `users`.`id`
        WHERE `sessions`.`id` = sid AND `sessions`.`ipAddress` = ip
            AND `users`.`prohibited` = 0 LIMIT 1;
    END IF;
    RETURN userId;
END $$

DROP FUNCTION IF EXISTS `getHost` $$
CREATE FUNCTION `getHost`(headers TEXT) RETURNS TEXT
NO SQL DETERMINISTIC
BEGIN
    DECLARE pos, len INT DEFAULT 0;
    SET pos = LOCATE('Host=', headers) + 5;
    SET len = LOCATE(';', headers, pos) - pos;
    RETURN SUBSTR(headers, pos, len);
END $$

DROP FUNCTION IF EXISTS `getConfig` $$
CREATE FUNCTION `getConfig` (sct VARCHAR(128), k VARCHAR(32)) RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE cval TEXT DEFAULT NULL;
    SELECT `val` INTO cval FROM `config` WHERE `id` = k AND `section` = sct LIMIT 1;
    RETURN cval;
END $$

DROP FUNCTION IF EXISTS `setConfig` $$
CREATE FUNCTION `setConfig`(sct VARCHAR(128),k VARCHAR(32),cval TEXT) RETURNS TINYINT
MODIFIES SQL DATA
BEGIN
    DECLARE exst TINYINT DEFAULT 0;
    SELECT COUNT(`id`) INTO exst FROM `config` WHERE `id`= k AND `section`= sct;
    IF exst > 0 THEN
        UPDATE `config` SET `val` = cval WHERE `id` = k AND `section` = sct;
    END IF;
    RETURN exst;
END $$

DROP FUNCTION IF EXISTS `isBot` $$
CREATE FUNCTION `isBot`(headers TEXT) RETURNS TINYINT
NO SQL DETERMINISTIC
BEGIN
    IF LOCATE('bot', headers) < 1 THEN
        RETURN 0;
    END IF;
    IF LOCATE('/bot', headers) > 0 OR LOCATE('bot/', headers) > 0 
        OR LOCATE('bot.', headers) > 0 THEN
        RETURN 1;
    END IF;
    RETURN 0;
END $$

DROP FUNCTION IF EXISTS `urize` $$
CREATE FUNCTION `urize`(fromWeb VARCHAR(256)) RETURNS VARCHAR(256)
NO SQL
BEGIN
    DECLARE outStr VARCHAR(256) DEFAULT '';
    DECLARE pos, len INT DEFAULT 1;
    DECLARE oneChar CHAR(1);
    SET fromWeb = TRIM(LOWER(fromWeb));
    SET fromWeb = REPLACE(fromWeb, ' ', '-');
    SET len = LENGTH(fromWeb);
    WHILE len >= pos DO
        SET oneChar = SUBSTR(fromWeb, pos, 1);
        IF (oneChar >= 'a' AND oneChar <= 'z') 
            OR (oneChar >= '0' AND oneChar <= '9') 
            OR oneChar = '-' OR oneChar = '/' THEN
                SET outStr = CONCAT(outStr, oneChar);
        END IF;
        SET pos = pos + 1;
    END WHILE;
    RETURN outStr;
END $$

DROP FUNCTION IF EXISTS `filesafe` $$
CREATE FUNCTION `filesafe`(fromWeb VARCHAR(1024)) RETURNS VARCHAR(1024)
NO SQL
BEGIN
    DECLARE outStr VARCHAR(256) DEFAULT '';
    DECLARE pos, len INT DEFAULT 1;
    DECLARE oneChar CHAR(1);
    SET fromWeb = TRIM(fromWeb);
    SET fromWeb = REPLACE(fromWeb, ' ', '_');
    SET len = LENGTH(fromWeb);
    WHILE len >= pos DO
        SET oneChar = SUBSTR(fromWeb, pos, 1);
        IF (oneChar >= 'a' AND oneChar <= 'z') 
            OR (oneChar >= 'A' AND oneChar <= 'Z') 
            OR (oneChar >= '0' AND oneChar <= '9') 
            OR oneChar = '-' OR oneChar = '/' OR oneChar = '.' THEN
                SET outStr = CONCAT(outStr, oneChar);
        END IF;
        SET pos = pos + 1;
    END WHILE;
    RETURN outStr;
END $$

DROP FUNCTION IF EXISTS `isImage` $$
CREATE FUNCTION `isImage`(uri TEXT) RETURNS TINYINT
READS SQL DATA
BEGIN
    DECLARE formats TEXT DEFAULT NULL;
    DECLARE ext VARCHAR(32) DEFAULT '';
    SET formats = getConfig('Media','image_formats');
    IF formats IS NULL THEN
        SET formats = '|jpg|jpeg|png|gif|tiff|svg|';
    END IF;
    SET ext = LOWER(uri);
    WHILE LOCATE('.', ext) > 0 DO
        SET ext = SUBSTR(ext, LOCATE('.', ext) + 1);
    END WHILE;
    SET ext = CONCAT('|',ext,'|');
    IF LOCATE(ext, formats) > 0 THEN
        RETURN 1;
    END IF;
    RETURN 0;
END $$

DROP FUNCTION IF EXISTS `descript` $$
CREATE FUNCTION `descript`(fromWeb TEXT) RETURNS TEXT
NO SQL
BEGIN
    DECLARE outStr, piece TEXT DEFAULT '';
    DECLARE pos, pos2, len INT DEFAULT 1;
    SET len = LENGTH(fromWeb);
    WHILE len > pos DO
        SET pos2 = LOCATE('<', fromWeb, pos);
        IF pos2 > 0 THEN
            SET outStr = CONCAT(outStr, SUBSTR(fromWeb, pos, pos2 - pos));
            SET piece = LTRIM(SUBSTR(fromWeb, pos2 + 1));
            IF LOWER(SUBSTR(piece, 1, 6)) = 'script' THEN
                SET pos = LOCATE('>', fromWeb, pos2) + 1;
                IF pos = 1 THEN
                    SET pos = len;
                END IF;
            ELSE
                SET pos = pos2 + 1;
                SET outStr = CONCAT(outStr, '<');
            END IF;
        ELSE
            SET outStr = CONCAT(outStr, SUBSTR(fromWeb, pos));
            SET pos = len;
        END IF;
    END WHILE;
    RETURN outStr;
END $$

DROP FUNCTION IF EXISTS `tease` $$
CREATE FUNCTION `tease`(fromWeb TEXT) RETURNS VARCHAR(256)
NO SQL
BEGIN
    DECLARE outStr TEXT DEFAULT '';
    DECLARE pos, pos2, len INT DEFAULT 1;
    SET fromWeb = REPLACE(fromWeb, '&nbsp;', ' ');
    SET len = LENGTH(fromWeb);
    WHILE len > pos DO
        SET pos2 = LOCATE('<', fromWeb, pos);
        IF pos2 > 0 THEN
            SET outStr = CONCAT(outStr, SUBSTR(fromWeb, pos, pos2 - pos));
            SET pos = LOCATE('>', fromWeb, pos2) + 1;
        ELSE
            SET outStr = CONCAT(outStr, SUBSTR(fromWeb, pos));
            SET pos = len;
        END IF;
    END WHILE;
    RETURN CONCAT(SUBSTR(outStr, 1, 250),'...');
END $$

DROP FUNCTION IF EXISTS `getTeasePic` $$
CREATE FUNCTION `getTeasePic`(htmlContent TEXT) RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE pos, len INT DEFAULT 0;
    DECLARE imid BIGINT DEFAULT 0;
    DECLARE imgSrc TEXT DEFAULT '';
    SET pos = LOCATE('<img', LOWER(htmlContent));
    IF pos > 0 THEN
        SET imgSrc = SUBSTR(htmlContent, pos);
        SET pos = LOCATE('src="', LOWER(imgSrc));
        IF pos > 0 THEN
            SET imgSrc = SUBSTR(imgSrc, pos + 5);
            SET imgSrc = SUBSTR(imgSrc, 1, LOCATE('"', imgSrc) - 1);
            SELECT `id` INTO imid FROM `media` WHERE `uri` = imgSrc LIMIT 1;
            IF imid > 0 THEN
                SELECT `thumb` INTO imgSrc FROM `media` WHERE `id` = imid;
            END IF;
        ELSE
            SET imgSrc = '';
        END IF;
    END IF;
    RETURN imgSrc;
END $$

DROP FUNCTION IF EXISTS `published` $$
CREATE FUNCTION `published`(indate DATE) RETURNS VARCHAR(32)
READS SQL DATA
BEGIN
    DECLARE fmt TEXT DEFAULT '%b %D, %Y';
    IF indate IS NULL THEN
        RETURN 'Unpublished';
    END IF;
    SELECT `val` INTO fmt FROM `config` 
        WHERE `id` = 'date_format' AND `section` = 'core' LIMIT 1;
    RETURN DATE_FORMAT(indate, fmt);
END $$

DROP FUNCTION IF EXISTS `listRoles` $$
CREATE FUNCTION `listRoles`(userId BIGINT) RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE done, indx INT DEFAULT 0;
    DECLARE list TEXT DEFAULT '';
    DECLARE val VARCHAR(256);
    DECLARE cursr CURSOR FOR SELECT `label` FROM `roles` 
        JOIN `user_roles` ON `roles`.`id` = `user_roles`.`idRole`
            AND `user_roles`.`idUser` = userId
        ORDER BY `roles`.`id`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cursr;
    REPEAT
        FETCH cursr INTO val;
        IF NOT done THEN
            IF indx > 0 THEN
                SET list = CONCAT(list,', ');
            END IF;
            SET indx = indx + 1;
            SET list = CONCAT(list, val);
        END IF;
    UNTIL done END REPEAT;
    CLOSE cursr;
    RETURN list;
END $$

DROP FUNCTION IF EXISTS `refreshPages` $$
CREATE FUNCTION `refreshPages`() RETURNS TEXT
MODIFIES SQL DATA
BEGIN
    DECLARE pageList TEXT DEFAULT '';
    DECLARE pageTpl VARCHAR(1024) DEFAULT '';
    DECLARE chk INT DEFAULT 0;
    
    SET pageList = tpl_list(CONCAT(`getConfig`('Site','tplroot'),'/public/pages'));
    IF pageList IS NULL OR pageList = '' THEN
        RETURN CONCAT(`getConfig`('Site','tplroot'),'/public/pages is empty!');
    END IF;

    UPDATE `pages` SET `published` = 0 WHERE `published` = -1;
    UPDATE `pages` SET `published` = -1
        WHERE LOCATE(CONCAT('\n',`tpl`,'\n'), CONCAT('\n', pageList)) < 1;
            
    WHILE LOCATE('\n', pageList) > 0 DO
        SET pageTpl = SUBSTR( pageList, 1, LOCATE('\n', pageList) - 1 );
        SELECT COUNT(`tpl`) INTO chk FROM `pages` WHERE `tpl` = pageTpl;
        IF chk < 1 AND pageTpl != '' THEN
            INSERT INTO `pages` (`tpl`) VALUES (pageTpl);
        END IF;
        SET pageList = SUBSTR( pageList, LOCATE('\n', pageList) + 1 );
    END WHILE;
    
    RETURN '';
END $$

DROP PROCEDURE IF EXISTS `nextArticle` $$
CREATE PROCEDURE `nextArticle` (articleId BIGINT)
BEGIN
    DECLARE pubChk TINYINT DEFAULT 0;
    SELECT `articles`.`id`,`content`,`title`,`uri`,`numViews`, 
        published(`dtPublish`) AS pubDate,`users`.`displayName`,
        `users`.`url`,`users`.`avatarUri` 
        FROM `articles` LEFT JOIN `users` ON `articles`.`idAuthor` = `users`.`id`
        WHERE `articles`.`id` = articleId AND `dtPublish` IS NOT NULL LIMIT 1;
    SELECT `title` INTO @ptitle FROM `articles` 
        WHERE `id` = articleId AND `dtPublish` IS NOT NULL LIMIT 1;
    IF @ptitle IS NOT NULL AND @ptitle != '' AND isBot(@mvp_headers) = 0 THEN
        UPDATE `articles` SET `numViews` = `numViews` + 1 
            WHERE `id` = articleId;
    END IF;
    SELECT `tags`.* FROM `nextData`.`tags` 
        JOIN `nextData`.`article_tags` ON `tags`.`id` = `article_tags`.`idTag`
        AND `article_tags`.`idArticle` = articleId
        ORDER BY `tags`.`displayName`;
    IF @mobile = 'Y' THEN
        SELECT `published` INTO pubChk FROM `pages` 
            WHERE `tpl` = `getConfig`('Site','articleLayoutMobile');
        IF pubChk = 1 THEN
            SET @mvp_template = CONCAT('pages/',`getConfig`('Site','articleLayoutMobile'));
        END IF;
    END IF;
    IF pubChk = 0 THEN
        SELECT `published` INTO pubChk FROM `pages` 
            WHERE `tpl` = `getConfig`('Site','articleLayout');
        IF pubChk = 1 THEN
            SET @mvp_template = CONCAT('pages/',`getConfig`('Site','articleLayout'));
        ELSE
            SET @mvp_template = CONCAT('pages/',`getConfig`('Site','404Page'));
        END IF;
    END IF;
END $$

DROP PROCEDURE IF EXISTS `nextCategory` $$
CREATE PROCEDURE `nextCategory` (categoryId BIGINT)
BEGIN
    DECLARE num, articleId BIGINT DEFAULT 0;
    DECLARE listLimit INT DEFAULT 0;
    DECLARE pubChk TINYINT DEFAULT 0;
    SELECT COUNT(`articles`.`id`) INTO num 
        FROM `articles` 
        JOIN `article_categories` ON `articles`.`id` = `article_categories`.`idArticle`
            AND `article_categories`.`idCategory` = categoryId
        WHERE `dtPublish` IS NOT NULL ORDER BY `dtPublish` DESC;

    IF num = 1 THEN
        SELECT `articles`.`id` INTO articleId 
            FROM `articles` 
            JOIN `article_categories` ON `articles`.`id` = `article_categories`.`idArticle`
                AND `article_categories`.`idCategory` = categoryId
            WHERE `dtPublish` IS NOT NULL LIMIT 1;
        CALL `nextArticle`(articleId);
    ELSE
        SET listLimit = `getConfig`('Site','listLimit');
        IF num < 1 THEN
            SET listLimit = 20;
        END IF;
        SELECT `articles`.`id`, `teaser`, `title`, `articles`.`uri`,
            published(`dtPublish`) AS pubDate, `teasePic`, 
            `article_categories`.`idCategory`
            FROM `articles` 
            JOIN `article_categories` ON `articles`.`id` = `article_categories`.`idArticle`
                AND `article_categories`.`idCategory` = categoryId
            WHERE `dtPublish` IS NOT NULL ORDER BY `dtPublish` DESC LIMIT listLimit;
            
        IF @mobile = 'Y' THEN
            SELECT `published` INTO pubChk FROM `pages` 
                WHERE `tpl` = `getConfig`('Site','listLayoutMobile');
            IF pubChk = 1 THEN
                SET @mvp_template = CONCAT('pages/',`getConfig`('Site','listLayoutMobile'));
            END IF;
        END IF;
        IF pubChk = 0 THEN
            SELECT `published` INTO pubChk FROM `pages` 
                WHERE `tpl` = `getConfig`('Site','listLayout');
            IF pubChk = 1 THEN
                SET @mvp_template = CONCAT('pages/',`getConfig`('Site','listLayout'));
            ELSE
                SET @mvp_template = CONCAT('pages/',`getConfig`('Site','404Page'));
            END IF;
        END IF;
    
        SELECT CONCAT(getHost(@mvp_headers), ' - ', `displayName`) 
            INTO @ptitle FROM `categories` WHERE `id` = categoryId LIMIT 1;
    END IF;
END $$

DROP PROCEDURE IF EXISTS `nextTag` $$
CREATE PROCEDURE `nextTag` (tagId BIGINT)
BEGIN
    DECLARE tagline TEXT DEFAULT '';
    DECLARE num, articleId BIGINT DEFAULT 0;
    DECLARE listLimit INT DEFAULT 0;
    DECLARE pubChk TINYINT DEFAULT 0;
    SET @ptitle = `nextData`.`getHost`(@mvp_headers);
    SELECT COUNT(`articles`.`id`) INTO num FROM `articles` 
        JOIN `article_tags` ON `articles`.`id` = `article_tags`.`idArticle` 
            AND `article_tags`.`idTag` = tagId 
        WHERE `dtPublish` IS NOT NULL;
    IF num = 1 THEN
        SELECT `articles`.`id` INTO articleId FROM `articles` 
            JOIN `article_tags` ON `articles`.`id` = `article_tags`.`idArticle` 
                AND `article_tags`.`idTag` = tagId 
            WHERE `dtPublish` IS NOT NULL LIMIT 1;
    END IF;
    
    IF articleId > 0 THEN
        CALL `nextArticle`(articleId);
    ELSE
        SET listLimit = `getConfig`('Site','listLimit');
        IF num < 1 THEN
            SET listLimit = 20;
        END IF;
        SELECT `articles`.`id`, `teaser`, `title`, `articles`.`uri`,
            published(`dtPublish`) AS pubDate, `teasePic`
            FROM `articles` 
            JOIN `article_tags` ON `articles`.`id` = `article_tags`.`idArticle` 
                AND `article_tags`.`idTag` = tagId 
            WHERE `dtPublish` IS NOT NULL ORDER BY `dtPublish` DESC LIMIT listLimit;
        SELECT CONCAT(@ptitle, ' - ', `displayName`) INTO @ptitle 
            FROM `tags` WHERE `id` = tagId LIMIT 1;
        
        IF @mobile = 'Y' THEN
            SELECT `published` INTO pubChk FROM `pages` 
                WHERE `tpl` = `getConfig`('Site','listLayoutMobile');
            IF pubChk = 1 THEN
                SET @mvp_template = CONCAT('pages/',`getConfig`('Site','listLayoutMobile'));
            END IF;
        END IF;
        IF pubChk = 0 THEN
            SELECT `published` INTO pubChk FROM `pages` 
                WHERE `tpl` = `getConfig`('Site','listLayout');
            IF pubChk = 1 THEN
                SET @mvp_template = CONCAT('pages/',`getConfig`('Site','listLayout'));
            ELSE
                SET @mvp_template = CONCAT('pages/',`getConfig`('Site','404Page'));
            END IF;
        END IF;
    END IF;
END $$

DROP FUNCTION IF EXISTS `catIndent` $$
CREATE FUNCTION `catIndent`(parentId BIGINT) RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE indent TEXT DEFAULT '';
    WHILE parentId > 1 DO
        SET indent = CONCAT(indent, '&nbsp;&nbsp;');
        SELECT `idParent` INTO parentId FROM `categories` 
            WHERE `id` = parentId LIMIT 1;
    END WHILE;
    RETURN indent;
END $$

DROP FUNCTION IF EXISTS `publicCategoriesHtml` $$
CREATE FUNCTION `publicCategoriesHtml` () RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE done, pos, deep INT DEFAULT 0;
    DECLARE cid, pid, parentId, prevCatId BIGINT DEFAULT 0;
    DECLARE curi, cname VARCHAR(1024);
    DECLARE listHtml TEXT DEFAULT '<ol class="cat-list">';
    DECLARE queue TEXT DEFAULT '1|';
    DECLARE cursr CURSOR FOR SELECT `id`, `idParent`, `uri`, `displayName`
        FROM `categories` WHERE `categories`.`id` > 1 AND `categories`.`ord` > 0 
        ORDER BY `categories`.`ord`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET parentId = 1;
    OPEN cursr;
    REPEAT
        FETCH cursr INTO cid, pid, curi, cname;
        IF NOT done THEN
            IF prevCatId > 0 AND pid = parentId THEN
                SET listHtml = CONCAT(listHtml, '</li>');
            END IF;
            IF pid != parentId THEN
                IF pid = prevCatId THEN
                    SET deep = deep + 1;
                    SET listHtml = CONCAT(listHtml, '<ol class="cat-list">');
                    SET queue = CONCAT(pid, '|', queue);
                    SET parentId = pid;
                ELSE
                    WHILE parentId != pid DO
                        SET deep = deep - 1;
                        SET listHtml = CONCAT(listHtml, '</ol></li>');
                        SET queue = SUBSTR(queue, LOCATE('|', queue) + 1);
                        SET pos = LOCATE('|', queue);
                        SET parentId = SUBSTR(queue, 1, pos - 1);
                    END WHILE;
                END IF;
            END IF;
            SET listHtml = CONCAT(listHtml,'<li class="cat-item"><a href="',curi,
                                  '">',cname,'</a>');
            SET prevCatId = cid;
        END IF;
    UNTIL done END REPEAT;
    CLOSE cursr;
    WHILE deep > -1 DO
        SET deep = deep - 1;
        SET listHtml = CONCAT(listHtml,'</li></ol>');
    END WHILE;
    RETURN listHtml;
END $$

DROP FUNCTION IF EXISTS `categoryHtmlParse` $$
CREATE FUNCTION `categoryHtmlParse` (html TEXT) RETURNS BIGINT
MODIFIES SQL DATA
BEGIN
    DECLARE catId, maxOrd, parentId BIGINT DEFAULT 0;
    DECLARE curi, cname VARCHAR(1024) DEFAULT '';
    DECLARE queue TEXT DEFAULT '1|';
    DECLARE pos, len INT DEFAULT 0;

    SET parentId = 1;
    UPDATE `categories` SET `ord` = 0;
    WHILE LOCATE('<li', html) > 0 DO
        SET pos = LOCATE('</ol>', html);
        WHILE pos > 0 AND pos < LOCATE('<li', html) DO
            SET html = SUBSTR(html, pos + 4);
            SET queue = SUBSTR(queue, LOCATE('|', queue) + 1);
            SET pos = LOCATE('|', queue);
            SET parentId = SUBSTR(queue, 1, pos - 1);
            SET pos = LOCATE('</ol>', html);
        END WHILE;
        SET pos = LOCATE('data-id="', html) + 9;
        SET len = LOCATE('"', html, pos) - pos;
        SET catId = SUBSTR(html, pos, len);
        SET pos = LOCATE('data-uri="', html) + 10;
        SET len = LOCATE('"', html, pos) - pos;
        SET curi = `urize`(SUBSTR(html, pos, len));
        SET pos = LOCATE('<div', html) + 4;
        SET pos = LOCATE('>', html, pos) + 1;
        SET len = LOCATE('</div>', html, pos) - pos;
        SET cname = `descript`(SUBSTR(html, pos, len));
        SELECT MAX(`ord`) INTO maxOrd FROM `categories`;
        IF catId IS NULL OR catId = 0 THEN
            INSERT INTO `categories` (`idParent`,`uri`,`displayName`,`ord`)
                VALUES (parentId, curi, cname, maxOrd + 1);
            SET catId = LAST_INSERT_ID();
        ELSE
            UPDATE `categories` SET `idParent` = parentId, `uri` = curi, 
                                    `displayName` = cname, `ord` = maxOrd + 1
            WHERE `id` = catId;
        END IF;
        SET html = SUBSTR(html, LOCATE('</div', html) + 4);
        SET pos = LOCATE('<ol', html);
        SET len = LOCATE('</li', html);
        IF pos > 0 AND len > pos THEN
            SET queue = CONCAT(catId, '|', queue);
            SET parentId = catId;
        END IF;
    END WHILE;
    RETURN maxOrd + 1;
END $$

DROP FUNCTION IF EXISTS `resetArticleCategories` $$
CREATE FUNCTION `resetArticleCategories`(articleId BIGINT) RETURNS TINYINT
MODIFIES SQL DATA
BEGIN
    DECLARE catLineage, catId, done BIGINT DEFAULT 0;
    DECLARE cursr CURSOR FOR SELECT `id`, `idCategory` FROM `articles`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    IF articleId IS NULL THEN
        OPEN cursr;
        REPEAT
            FETCH cursr INTO articleId, catId;
            IF NOT done THEN
                DELETE FROM `article_categories` WHERE `idArticle` = articleId;
                SET catLineage = catId;
                WHILE catLineage > 1 DO
                    INSERT INTO `article_categories` (`idArticle`,`idCategory`)
                        VALUES (articleId, catLineage);
                    SELECT `idParent` INTO catLineage FROM `categories`
                        WHERE `id` = catLineage;
                END WHILE;
                INSERT INTO `article_categories` (`idArticle`,`idCategory`)
                    VALUES (articleId, 1);
            END IF;
        UNTIL done END REPEAT;
        CLOSE cursr;
    ELSE
        DELETE FROM `article_categories` WHERE `idArticle` = articleId;
        SELECT `idCategory` INTO catId FROM `articles` WHERE `id` = articleId;
        SET catLineage = catId;
        WHILE catLineage > 1 DO
            INSERT INTO `article_categories` (`idArticle`,`idCategory`)
                VALUES (articleId, catLineage);
            SELECT `idParent` INTO catLineage FROM `categories`
                WHERE `id` = catLineage;
        END WHILE;
        INSERT INTO `article_categories` (`idArticle`,`idCategory`)
            VALUES (articleId, 1);
    END IF;
    RETURN 1;
END $$

DROP FUNCTION IF EXISTS `checkDuplicateUri` $$
CREATE FUNCTION `checkDuplicateUri`(articleId BIGINT, auri VARCHAR(256)) RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE itelm, tipe VARCHAR(256);
    DECLARE warnins TEXT DEFAULT '';
    DECLARE done INT DEFAULT 0;
    DECLARE cursr CURSOR FOR 
        SELECT `tpl`, 'Page' FROM `pages` 
            WHERE `uri` = auri AND `published` = 1
        UNION SELECT `title`, 'Article' FROM `articles` 
            WHERE `uri` = auri AND `id` != articleId
        UNION SELECT `displayName`, 'Category' FROM `categories` 
            WHERE `uri` = auri AND `ord` > 0
        UNION SELECT `displayName`, 'Tag' FROM `tags` 
            WHERE `uri` = auri;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cursr;
    REPEAT
        FETCH cursr INTO itelm, tipe;
        IF NOT done THEN
            SET warnins = CONCAT(warnins, tipe, ' &quot;', itelm, '&quot; matches uri<br />');
        END IF;
    UNTIL done END REPEAT;
    CLOSE cursr;
    RETURN warnins;
END $$

DROP FUNCTION IF EXISTS `notifyNewArticle` $$
CREATE FUNCTION `notifyNewArticle` (articleId BIGINT, host TEXT) RETURNS INT
READS SQL DATA
BEGIN
    DECLARE titl, teasr VARCHAR(256) DEFAULT '';
    DECLARE authorName, url, eaddr, recipName, fromEmail, mailServer VARCHAR(1024) DEFAULT '';
    DECLARE ebody, sendBody, errs TEXT DEFAULT '';
    DECLARE done, numSent, errChk INT DEFAULT 0;
    DECLARE cursr CURSOR FOR SELECT `email`, `displayName` FROM `users`
        WHERE `notifyArticles` > 0 AND `prohibited` = 0;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SET fromEmail = `getConfig`('Site','fromEmail');
    SET mailServer = `getConfig`('Site','mailServer');
    SELECT `title`, `teaser`, CONCAT('http://', host, '/', `uri`),
        `displayName` INTO titl, teasr, url, authorName
        FROM `articles` LEFT JOIN `users` ON `articles`.`idAuthor` = `users`.`id`
        WHERE `articles`.`id` = articleId AND `dtPublish` IS NOT NULL LIMIT 1;
    IF titl != '' AND teasr != '' THEN
        SET ebody = np_loadfile(CONCAT(`getConfig`('Site','tplroot'),'/admin/email/NewArticle.tpl'));
        IF ebody != '' THEN
            SET ebody = REPLACE(ebody, '<# TITLE #>', titl);
            SET ebody = REPLACE(ebody, '<# TEASER #>', teasr);
            SET ebody = REPLACE(ebody, '<# URL #>', url);
            SET ebody = REPLACE(ebody, '<# AUTHOR #>', authorName);
            SET ebody = REPLACE(ebody, '<# DOMAIN #>', host);
            SET ebody = REPLACE(ebody, '<# FROM #>', fromEmail);
        ELSE
            INSERT INTO `mail_errors` (`theDate`,`errors`) 
                VALUES (NOW(), 'Notification template appears to be missing or empty.');
            RETURN 0;
        END IF;
        OPEN cursr;
        REPEAT
            FETCH cursr INTO eaddr, recipName;
            IF NOT done THEN
                IF recipName = '' THEN
                    SET recipName = CONCAT('<',eaddr,'>');
                ELSE
                    SET recipName = CONCAT('"',recipName,'" <',eaddr,'>');
                END IF;
                SET sendBody = REPLACE(ebody, '<# RECIPIENT #>', recipName);
                SET errChk = emailer(eaddr, sendBody, mailServer, fromEmail);
                IF errChk != 0 THEN
        			SET errs = CONCAT(errs, 'Error ',errChk,' for addr ',eaddr,'<br />');
                ELSE
                    SET numSent = numSent + 1;
                END IF;
            END IF;
        UNTIL done END REPEAT;
        CLOSE cursr;
        IF errs != '' THEN
            INSERT INTO `mail_errors` (`theDate`,`errors`) VALUES (NOW(), errs);
        END IF;
    ELSE
        INSERT INTO `mail_errors` (`theDate`,`errors`) 
            VALUES (NOW(), 'The published article seems to have no title or content.');
        RETURN 0;
    END IF;
    RETURN numSent;
END $$

DELIMITER ;


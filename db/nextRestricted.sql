-- 
--  NextPress Data Definitions, Functions & Procedures
--  No direct access by webserver
--  Copyright (C) 2016 Lowadobe Web Services, LLC 
--  web: http://nextpress.online/
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
        SET ext = SUBSTR(uri, LOCATE('.', ext) + 1);
    END WHILE;
    SET ext = CONCAT('|',ext,'|');
    IF LOCATE(ext, formats) > 0 THEN
        RETURN 1;
    END IF;
    RETURN 0;
END $$

DROP FUNCTION IF EXISTS `publishPage` $$
CREATE FUNCTION `publishPage`(pageUri VARCHAR(512), pageMobile TINYINT) 
    RETURNS VARCHAR(64)
MODIFIES SQL DATA
BEGIN
    DECLARE tplResult, piece, pageContent TEXT;
    DECLARE pos, pos2, len, piecePos, pieceEnd INT DEFAULT 1;
    DECLARE dropinImg, dropinTpl, pageTpl VARCHAR(1024) DEFAULT '';
    SELECT `content`, `tpl` INTO pageContent, pageTpl FROM `pages`
        WHERE `uri` = pageUri AND `mobile` = pageMobile LIMIT 1;
    SET len = LENGTH(pageContent);
    WHILE len > pos DO
        SET pos2 = LOCATE('<', pageContent, pos);
        IF pos2 > 0 THEN
            SET tplResult = CONCAT(tplResult, SUBSTR(pageContent, pos, pos2 - pos));
            SET piece = LTRIM(SUBSTR(pageContent, pos2 + 1));
            SET pieceEnd = LOCATE('>', piece);
            SET piecePos = LOCATE('/media/dropins/', piece);
            IF pieceEnd != 0 AND piecePos != 0 AND piecePos < pieceEnd THEN
                SET piece = SUBSTR(piece, piecePos);
                SET pieceEnd = LOCATE('"', piece);
                SET dropinImg = SUBSTR(piece, 1, pieceEnd);
                SET dropinTpl = '';
                SELECT `tpl` INTO dropinTpl FROM `dropins` 
                    WHERE `img` = dropinImg LIMIT 1;
                IF dropinTpl != '' THEN
                    SET tplResult = CONCAT(tplResult,'<# INCLUDE dropins/',dropinTpl,' #>');
                END IF;
                
                SET pos = LOCATE('>', pageContent, pos2) + 1;
                IF pos = 1 THEN
                    SET pos = len;
                END IF;
            ELSE
                SET pos = pos2 + 1;
                SET tplResult = CONCAT(tplResult, '<');
            END IF;
        ELSE
            SET tplResult = CONCAT(tplResult, SUBSTR(pageContent, pos));
            SET pos = len;
        END IF;
    END WHILE;
    
    IF tplResult = '' THEN
        RETURN 'Error: Resulting template is empty.';
    END IF;
    
    SET pos = file_write(CONCAT(`getConfig`('Site','tplroot'),
                         '/public/pages/',pageTpl,'.tpl'),tplResult);
    IF pos != 0 THEN
        RETURN CONCAT('Error saving template (',pos,')');
    END IF;

    UPDATE `nextData`.`pages` SET `published` = 1 
        WHERE `uri` = pageUri AND `mobile` = pageMobile;

    SET pos = reload_apache();
    IF pos != 0 THEN
        RETURN 'Webserver reload failed. Please manually restart/reload.';
    END IF;
    RETURN 'Page successfully published.';
END $$

DROP FUNCTION IF EXISTS `removePage` $$
CREATE FUNCTION `removePage`(pageUri VARCHAR(512), pageMobile TINYINT) 
    RETURNS VARCHAR(64)
MODIFIES SQL DATA
BEGIN
    DECLARE pageTpl VARCHAR(1024) DEFAULT NULL;
    DECLARE errno INT DEFAULT 0;
    
    UPDATE `nextData`.`pages` SET `published` = 0 
        WHERE `uri` = pageUri AND `mobile` = pageMobile;

    SELECT `tpl` INTO pageTpl FROM `pages` 
        WHERE `uri` = pageUri AND `mobile` = pageMobile LIMIT 1;
    SET errno = file_delete(CONCAT(`getConfig`('Site','tplroot'),
                            '/pages/',pageTpl,'.tpl'));
    
    IF errno = 0 THEN
        RETURN 'Page successfully unpublished';
    END IF;
    
    RETURN CONCAT('Error deleting template (',errno,')');

    SET errno = reload_apache();
    IF errno != 0 THEN
        RETURN 'Webserver reload failed. Please manually restart/reload.';
    END IF;
    RETURN 'Page successfully unpublished.';
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

DROP PROCEDURE IF EXISTS `nextArticle` $$
CREATE PROCEDURE `nextArticle` (articleId BIGINT)
BEGIN
    SELECT `articles`.`id`,`content`,`title`,`uri`,`numViews`, 
        published(`dtPublish`) AS pubDate,`users`.`displayName`,
        `users`.`url`,`users`.`avatarUri` 
        FROM `articles` LEFT JOIN `users` ON `articles`.`idAuthor` = `users`.`id`
        WHERE `articles`.`id` = articleId AND `dtPublish` IS NOT NULL LIMIT 1;
    SELECT `title` INTO @ptitle FROM `articles` 
        WHERE `id` = articleId AND `dtPublish` IS NOT NULL LIMIT 1;
    IF @ptitle IS NOT NULL AND @ptitle != '' AND isBot(@mvp_headers) = 0 THEN
        UPDATE `articles` SET `numViews` = `numViews` + 1 
            WHERE `id` = articleid;
    END IF;
    SELECT `tags`.* FROM `nextData`.`tags` 
        JOIN `nextData`.`article_tags` ON `tags`.`id` = `article_tags`.`idTag`
        AND `article_tags`.`idArticle` = articleId
        ORDER BY `tags`.`displayName`;
    IF @mobile != 'Y' THEN
        SET @mvp_template = CONCAT('pages/',`getConfig`('Site','articleLayout'));
    ELSE
        SET @mvp_template = CONCAT('pages/',`getConfig`('Site','articleLayout'),'_mobile');
    END IF;
END $$

DROP PROCEDURE IF EXISTS `nextCategory` $$
CREATE PROCEDURE `nextCategory` (categoryId BIGINT)
BEGIN
    DECLARE num, articleId BIGINT DEFAULT 0;
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
        SELECT `articles`.`id`, `teaser`, `title`, `articles`.`uri`,
            published(`dtPublish`) AS pubDate,`media`.`uri` AS picUri, 
            `article_categories`.`idCategory`
            FROM `articles` 
            JOIN `article_categories` ON `articles`.`id` = `article_categories`.`idArticle`
                AND `article_categories`.`idCategory` = categoryId
            LEFT JOIN `media` ON `articles`.`idTeasePic` = `media`.`id` 
            WHERE `dtPublish` IS NOT NULL ORDER BY `dtPublish` DESC;
            
        IF @mobile != 'Y' THEN
            SET @mvp_template = CONCAT('pages/',`getConfig`('Site','listLayout'));
        ELSE
            SET @mvp_template = CONCAT('pages/',`getConfig`('Site','listLayoutMobile'));
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
        SELECT `articles`.`id`, `teaser`, `title`, `articles`.`uri`,
            published(`dtPublish`) AS pubDate, `media`.`uri` AS picUri
            FROM `articles` 
            JOIN `article_tags` ON `articles`.`id` = `article_tags`.`idArticle` 
                AND `article_tags`.`idTag` = tagId 
            LEFT JOIN `media` ON `articles`.`idTeasePic` = `media`.`id`
            WHERE `dtPublish` IS NOT NULL ORDER BY `dtPublish` DESC;
        SELECT CONCAT(@ptitle, ' - ', `displayName`) INTO @ptitle 
            FROM `tags` WHERE `id` = tagId LIMIT 1;
        
        IF @mobile != 'Y' THEN
            SET @mvp_template = CONCAT('pages/',`getConfig`('Site','listLayout'));
        ELSE
            SET @mvp_template = CONCAT('pages/',`getConfig`('Site','listLayoutMobile'));
        END IF;
    END IF;
END $$

DROP FUNCTION IF EXISTS `getTemplate` $$

DROP FUNCTION IF EXISTS `categoriesHtml` $$
CREATE FUNCTION `categoriesHtml` (parentId BIGINT) RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE cid BIGINT DEFAULT 0;
    DECLARE curi, cname VARCHAR(1024);
    DECLARE listHtml TEXT DEFAULT '';
    DECLARE cursr CURSOR FOR SELECT `id`, `uri`, `displayName` 
        FROM `categories` WHERE `idParent` = parentId ORDER BY `ord`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cursr;
    REPEAT
        FETCH cursr INTO cid, curi, cname;
        IF NOT done THEN
            IF listHtml = '' THEN
                SET listHtml = CONCAT('<ol class="dd-list" id="parent',parentId,'">');
            END IF;
            SET listHtml = CONCAT(listHtml,'<li class="dd-item" data-id="',cid,
                                  '" data-uri="',curi,'"><div class="dd-handle">',
                                  cname,'</div>',`categoriesHtml`(cid),'</li>');
        END IF;
    UNTIL done END REPEAT;
    CLOSE cursr;
    IF listHtml != '' THEN
        SET listHtml = CONCAT(listHtml,'</ol>');
    END IF;
    RETURN listHtml;
END $$

DROP FUNCTION IF EXISTS `publicCategories` $$
CREATE FUNCTION `publicCategories` (parentId BIGINT) RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE cid BIGINT DEFAULT 0;
    DECLARE curi, cname VARCHAR(1024);
    DECLARE listHtml TEXT DEFAULT '';
    DECLARE cursr CURSOR FOR SELECT `categories`.`id`, `categories`.`uri`, 
            `categories`.`displayName`
        FROM `categories`
        JOIN `article_categories` 
            ON `categories`.`id` = `article_categories`.`idCategory`
        JOIN `articles` 
            ON `article_categories`.`idArticle` = `articles`.`id`
            AND `articles`.`dtPublish` IS NOT NULL 
        WHERE `categories`.`idParent` = parentId 
        GROUP BY `categories`.`id` ORDER BY `categories`.`ord`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cursr;
    REPEAT
        FETCH cursr INTO cid, curi, cname;
        IF NOT done THEN
            IF listHtml = '' THEN
                SET listHtml = '<ol class="cat-list">';
            END IF;
            SET listHtml = CONCAT(listHtml,'<li class="cat-item"><a href="',curi,
                                  '">',cname,'</a>',`publicCategories`(cid),'</li>');
        END IF;
    UNTIL done END REPEAT;
    CLOSE cursr;
    IF listHtml != '' THEN
        SET listHtml = CONCAT(listHtml,'</ol>');
    END IF;
    RETURN listHtml;
END $$

DROP FUNCTION IF EXISTS `categoryLiParse` $$
CREATE FUNCTION `categoryLiParse` (html TEXT, parentId BIGINT) RETURNS TEXT
MODIFIES SQL DATA
BEGIN
    DECLARE catId, maxOrd BIGINT DEFAULT 0;
    DECLARE curi, cname VARCHAR(1024) DEFAULT '';
    DECLARE pos, len INT DEFAULT 0;
    SET pos = LOCATE('data-id="', html) + 9;
    SET len = LOCATE('"', html, pos) - pos;
    SET catId = SUBSTR(html, pos, len);
    SET pos = LOCATE('data-uri="', html) + 10;
    SET len = LOCATE('"', html, pos) - pos;
    SET curi = `urize`(SUBSTR(html, pos, len));
    SET pos = LOCATE('<div', html) + 4;
    SET pos = LOCATE('>', html, pos) + 1;
    SET len = LOCATE('</div>', html, pos) - pos;
    SET cname = SUBSTR(html, pos, len);
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
        SET html = `categoryOlParse`(html, catId);
    END IF;
    RETURN html;
END $$

DROP FUNCTION IF EXISTS `categoryOlParse` $$
CREATE FUNCTION `categoryOlParse` (html TEXT, parentId BIGINT) RETURNS TEXT
MODIFIES SQL DATA
BEGIN
    WHILE LOCATE('</ol', html) > 0 AND LOCATE('<li', html) > 0
          AND LOCATE('</ol', html) > LOCATE('<li', html) DO
        SET html = `categoryLiParse` (html, parentId);
    END WHILE;
    IF LOCATE('</ol', html) > 0 THEN
        SET html = SUBSTR(html, LOCATE(html, '</ol') + 4);
    END IF;
    RETURN html;
END $$

DROP FUNCTION IF EXISTS `resetArticleCategories` $$
CREATE FUNCTION `resetArticleCategories`() RETURNS TINYINT
MODIFIES SQL DATA
BEGIN
    DECLARE catLineage, articleId, catId, done BIGINT DEFAULT 0;
    DECLARE cursr CURSOR FOR SELECT `id`, `idCategory` FROM `articles`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cursr;
    REPEAT
        FETCH cursr INTO articleId, catId;
        IF NOT done THEN
            SET catLineage = catId;
            WHILE catLineage > 0 DO
                INSERT INTO `nextData`.`article_categories` (`idArticle`,`idCategory`)
                    VALUES (articleId, catLineage);
                SELECT `idParent` INTO catLineage FROM `nextData`.`categories`
                    WHERE `id` = catLineage;
            END WHILE;
        END IF;
    UNTIL done END REPEAT;
    CLOSE cursr;
    RETURN 1;
END $$

DROP FUNCTION IF EXISTS `notifyNewArticle` $$
CREATE FUNCTION `notifyNewArticle` (articleId BIGINT) RETURNS INT
READS SQL DATA
BEGIN
    RETURN 1;
END $$

DROP FUNCTION IF EXISTS `applyBlacklist` $$
CREATE FUNCTION `applyBlacklist` (ctext TEXT, tlist TEXT) RETURNS INT
NO SQL
BEGIN
    DECLARE term TEXT DEFAULT '';
    DECLARE pos INT DEFAULT 1;
    WHILE LENGTH(tlist) DO
        SET pos = LOCATE(',', tlist);
        IF pos > 0 THEN
            SET term = SUBSTR(tlist, 1, pos - 1);
            SET tlist = SUBSTR(tlist, pos + 1);
        ELSE
            SET term = tlist;
            SET tlist = '';
        END IF;
        IF LOCATE(TRIM(term), ctext) > 0 THEN
            RETURN 1; -- match!
        END IF;
    END WHILE;
    RETURN 0; -- no matches
END $$

DROP FUNCTION IF EXISTS `linkFilter` $$
CREATE FUNCTION `linkFilter` (ctext TEXT, numAllow INT) RETURNS INT
NO SQL
BEGIN
    DECLARE pos, len, numAllow, numCounted INT DEFAULT 0;
    SET len = LENGTH(ctext);
    WHILE pos < len DO
        SET pos = LOCATE('<', ctext, pos);
        IF pos = 0 THEN
            SET pos = len;
        ELSE
            IF LOCATE('a ',TRIM(LOWER(SUBSTR(ctext, pos)))) = 1 THEN
                SET numCounted = numCounted + 1;
            END IF;
        END IF;
        SET pos = pos + 1;
    END WHILE;
    IF numCounted > numAllow THEN
        RETURN 0; -- too many links, held
    END IF;
    RETURN 1;
END $$

DROP FUNCTION IF EXISTS `teaseComment` $$
CREATE FUNCTION `teaseComment`(cmt TEXT) RETURNS VARCHAR(140)
NO SQL
BEGIN
    DECLARE outStr TEXT DEFAULT '';
    DECLARE pos, pos2, len INT DEFAULT 1;
    SET cmt = REPLACE(cmt, '&nbsp;', ' ');
    SET len = LENGTH(cmt);
    WHILE len > pos DO
        SET pos2 = LOCATE('<', cmt, pos);
        IF pos2 > 0 THEN
            SET outStr = CONCAT(outStr, SUBSTR(cmt, pos, pos2 - pos));
            SET pos = LOCATE('>', cmt, pos2) + 1;
        ELSE
            SET outStr = CONCAT(outStr, SUBSTR(cmt, pos));
            SET pos = len;
        END IF;
    END WHILE;
    IF LENGTH(outStr) > 140 THEN
        SET outStr = CONCAT(SUBSTR(outStr, 1, 137),'...');
    END IF;
    RETURN outStr;
END $$

DROP FUNCTION IF EXISTS `commentNotifications` $$
CREATE FUNCTION `commentNotifications` (commentId BIGINT) RETURNS INT
MODIFIES SQL DATA
BEGIN
    RETURN 1;
END $$

DELIMITER ;

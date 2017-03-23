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
        SET ext = SUBSTR(uri, LOCATE('.', ext) + 1);
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
            WHERE `id` = articleId;
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
            published(`dtPublish`) AS pubDate, `teasePic`, 
            `article_categories`.`idCategory`
            FROM `articles` 
            JOIN `article_categories` ON `articles`.`id` = `article_categories`.`idArticle`
                AND `article_categories`.`idCategory` = categoryId
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
            published(`dtPublish`) AS pubDate, `teasePic`
            FROM `articles` 
            JOIN `article_tags` ON `articles`.`id` = `article_tags`.`idArticle` 
                AND `article_tags`.`idTag` = tagId 
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

DROP FUNCTION IF EXISTS `categoriesHtml` $$
CREATE FUNCTION `categoriesHtml` () RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE done, pos, deep INT DEFAULT 0;
    DECLARE cid, pid, parentId, prevCatId BIGINT DEFAULT 0;
    DECLARE curi, cname VARCHAR(1024);
    DECLARE listHtml TEXT DEFAULT '<ol class="dd-list" id="parent1">';
    DECLARE queue TEXT DEFAULT '1|';
    DECLARE cursr CURSOR FOR SELECT `id`, `idParent`, `uri`, `displayName` 
        FROM `categories` WHERE `id` > 1 AND `ord` > 0 ORDER BY `ord`;
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
                    SET listHtml = CONCAT(listHtml, '<ol class="dd-list" id="parent', pid, '">');
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
            SET listHtml = CONCAT(listHtml,'<li class="dd-item" data-id="',cid,
                                  '"><div id="',cid,'" class="dd-handle" data-uri="',curi,
                                  '" onmousedown="editCategory(this);">',cname,'</div>');
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

DROP FUNCTION IF EXISTS `categorySelector` $$
CREATE FUNCTION `categorySelector` (articleId BIGINT) RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE done, pos, deep, pub INT DEFAULT 0;
    DECLARE cid, pid, parentId, prevCatId, catSelected BIGINT DEFAULT 0;
    DECLARE curi, cname, indent VARCHAR(1024) DEFAULT '';
    DECLARE listHtml TEXT DEFAULT '<select name="catId"><option>Select a Category</option>';
    DECLARE queue TEXT DEFAULT '1|';
    DECLARE cursr CURSOR FOR SELECT `id`, `idParent`, `categories`.`uri`, `displayName`, `pages`.`published`
        FROM `categories` LEFT JOIN `pages` ON `categories`.`uri` = `pages`.`uri`
        WHERE `id` > 1 AND `ord` > 0 ORDER BY `ord`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SELECT `idCategory` INTO catSelected FROM `articles` WHERE `id` = articleId;
    SET parentId = 1;
    OPEN cursr;
    REPEAT
        FETCH cursr INTO cid, pid, curi, cname, pub;
        IF NOT done THEN
            IF pid != parentId THEN
                IF pid = prevCatId THEN
                    SET deep = deep + 1;
                    SET indent = REPEAT('&nbsp;&nbsp;', deep);
                    SET queue = CONCAT(pid, '|', queue);
                    SET parentId = pid;
                ELSE
                    WHILE parentId != pid DO
                        SET deep = deep - 1;
                        SET indent = REPEAT('&nbsp;&nbsp;', deep);
                        SET queue = SUBSTR(queue, LOCATE('|', queue) + 1);
                        SET pos = LOCATE('|', queue);
                        SET parentId = SUBSTR(queue, 1, pos - 1);
                    END WHILE;
                END IF;
            END IF;
            IF pub IS NULL OR pub = 0 THEN
                IF cid = catSelected THEN
                    SET listHtml = CONCAT(listHtml,'<option value="',cid,
                                          '" selected="selected">',
                                          indent,REPLACE(cname,'"',''),'</option>');
                ELSE
                    SET listHtml = CONCAT(listHtml,'<option value="',cid,
                                          '">',indent,REPLACE(cname,'"',''),'</option>');
                END IF;
            END IF;
            SET prevCatId = cid;
        END IF;
    UNTIL done END REPEAT;
    CLOSE cursr;
    SET listHtml = CONCAT(listHtml,'</select>');
    RETURN listHtml;
END $$

DROP FUNCTION IF EXISTS `publicCategories` $$
CREATE FUNCTION `publicCategories` () RETURNS TEXT
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
    DECLARE catLineage, articleId, catId, done BIGINT DEFAULT 0;
    DECLARE cursr CURSOR FOR SELECT `id`, `idCategory` FROM `articles`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    IF articleId IS NULL THEN
        OPEN cursr;
        REPEAT
            FETCH cursr INTO articleId, catId;
            IF NOT done THEN
                SET catLineage = catId;
                WHILE catLineage > 1 DO
                    INSERT INTO `article_categories` (`idArticle`,`idCategory`)
                        VALUES (articleId, catLineage);
                    SELECT `idParent` INTO catLineage FROM `categories`
                        WHERE `id` = catLineage;
                END WHILE;
            END IF;
        UNTIL done END REPEAT;
        CLOSE cursr;
    ELSE
        DELETE FROM `nextData`.`article_categories` WHERE `idArticle` = articleId;
        SELECT `idCategory` INTO catId FROM `articles` WHERE `id` = articleId;
        SET catLineage = catId;
        WHILE catLineage > 1 DO
            INSERT INTO `article_categories` (`idArticle`,`idCategory`)
                VALUES (articleId, catLineage);
            SELECT `idParent` INTO catLineage FROM `categories`
                WHERE `id` = catLineage;
        END WHILE;
    END IF;
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


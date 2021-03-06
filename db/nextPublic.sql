-- 
--  NextPress Public (non-SSL) Procedures
--  Copyright (C) 2017 Lowadobe Web Services, LLC 
--  web: http://nextpress.org/
--  email: lowadobe@gmail.com
--

DELIMITER $$

DROP PROCEDURE IF EXISTS `nextPage` $$
CREATE PROCEDURE `nextPage` (IN p BIGINT, INOUT full TINYINT,
                             OUT tagId BIGINT, OUT categoryId BIGINT)
BEGIN
    DECLARE articleId, stop BIGINT DEFAULT 0;
    DECLARE defaultUri, pageTpl TEXT DEFAULT '';
    SET tagId = 0;
    SET categoryId = 0;
    IF LOCATE('Mobile', @mvp_headers) > 0 THEN
        SET @mobile = 'Y';
    END IF;
    IF full IS NOT NULL AND full > 0 THEN
        SET @mobile = '';
    END IF;

    -- This conditional is for link compatibility with imported wordpress sites    
    IF p IS NOT NULL AND p > 0 THEN
        SELECT `id` INTO articleId FROM `nextData`.`articles` 
            WHERE `idwp` = p AND `dtPublish` IS NOT NULL LIMIT 1;
        IF articleId > 0 THEN
            CALL `nextData`.`nextArticle`(articleId);
            SET stop = 1;
        END IF;
    END IF;

    IF LOCATE('/', @mvp_uri) = 1 THEN
        SET @mvp_uri = SUBSTR(@mvp_uri, 2);
    END IF;

    IF stop = 0 THEN
        SELECT `tpl` INTO pageTpl FROM `nextData`.`pages` 
            WHERE `uri` = @mvp_uri AND `published` > 0 LIMIT 1;
        IF pageTpl != '' THEN
            IF @mobile = 'Y' THEN
                SELECT `tpl` INTO pageTpl FROM `nextData`.`pages` 
                    WHERE `uri` = @mvp_uri AND `published` > 0 AND `mobile` = 1 LIMIT 1;
            END IF;
            SET @mvp_template = CONCAT('pages/', pageTpl);
            SET stop = 1;
        END IF;
    END IF;
    
    IF stop = 0 THEN
        SELECT `id` INTO articleId FROM `nextData`.`articles` 
            WHERE `uri` = @mvp_uri AND `dtPublish` IS NOT NULL LIMIT 1;
        IF articleId > 0 THEN
            CALL `nextData`.`nextArticle`(articleId);
            SET stop = 1;
        END IF;
    END IF;
    
    IF stop = 0 THEN
        SELECT `id` INTO categoryId FROM `nextData`.`categories` 
            WHERE `uri` = @mvp_uri AND `ord` > 0 LIMIT 1;
        IF categoryId > 0 THEN
            CALL `nextData`.`nextCategory`(categoryId);
            SET stop = 1;
        END IF;
    END IF;
    
    IF stop = 0 THEN
        SELECT `id` INTO tagId FROM `nextData`.`tags` 
            WHERE `uri` = @mvp_uri LIMIT 1;
        IF tagId > 0 THEN
            CALL `nextData`.`nextTag`(tagId);
            SET stop = 1;
        END IF;
    END IF;
       
    IF stop = 0 AND @mvp_uri = '' THEN
        SET defaultUri = `nextData`.`getConfig`('Site','default_uri');
        SELECT `tpl` INTO pageTpl FROM `nextData`.`pages` 
            WHERE `uri` = defaultUri AND `published` > 0 LIMIT 1;
        IF pageTpl != '' THEN
            IF @mobile = 'Y' THEN
                SELECT `tpl` INTO pageTpl FROM `nextData`.`pages` 
                    WHERE `uri` = defaultUri AND `published` > 0 AND `mobile` = 1 LIMIT 1;
            END IF;
            SET @mvp_template = CONCAT('pages/', pageTpl);
        ELSE
            SELECT `id` INTO articleId FROM `nextData`.`articles` 
                WHERE `uri` = defaultUri AND `dtPublish` IS NOT NULL LIMIT 1;
            IF articleId > 0 THEN
                CALL `nextData`.`nextArticle`(articleId);
            ELSE
                CALL `nextData`.`nextCategory`(1);
            END IF;
        END IF;
        SET stop = 1;
    END IF;
    
    IF stop = 0 THEN
        SET @mvp_template = CONCAT('pages/', `nextData`.`getConfig`('Site','404Page'));
    END IF;
    
    SET @keywords = `nextData`.`getConfig`('Site','keywords');
    SET @domain = `nextData`.`getHost`(@mvp_headers);
END $$

-- Procedures for DropIns

DROP PROCEDURE IF EXISTS `Archives` $$
CREATE PROCEDURE `Archives`()
BEGIN
    SELECT `uri`, `title`, YEAR(`dtPublish`) AS yr, MONTHNAME(`dtPublish`) AS mnth 
    FROM `nextData`.`articles` AS archives 
    WHERE `dtPublish` IS NOT NULL ORDER BY `dtPublish` DESC;
END $$

DROP PROCEDURE IF EXISTS `Disqus` $$
CREATE PROCEDURE `Disqus`(OUT shortname TEXT)
BEGIN
    SET shortname = `nextData`.`getConfig`('Disqus','disqusId');
END $$

DROP PROCEDURE IF EXISTS `MainMenu` $$
CREATE PROCEDURE `MainMenu`(OUT htmlMenu TEXT)
BEGIN
    SET htmlMenu = `nextData`.`getConfig`('Site','mainMenu');
END $$

DROP PROCEDURE IF EXISTS `RelatedArticles` $$
CREATE PROCEDURE `RelatedArticles`(IN articleId BIGINT)
BEGIN
    DECLARE chkPub INT DEFAULT 0;
    SELECT COUNT(`id`) INTO chkPub FROM `nextData`.`articles`
        WHERE `id` = articleId AND `dtPublish` IS NOT NULL;
    IF chkPub > 0 THEN
        SELECT `articles`.`id`, `teaser`, `title`, `articles`.`uri`,
            published(`dtPublish`) AS pubDate, `media`.`uri` AS picUri
        FROM `nextData`.`articles` AS related
        JOIN `nextData`.`article_tags` ON `articles`.`id` = `article_tags`.`idArticle`
            AND `article_tags`.`idTag` IN
            ( SELECT `idTag` FROM `nextData`.`article_tags` WHERE `idArticle` = articleId )
        LEFT JOIN `media` ON `articles`.`idTeasePic` = `media`.`id`
        WHERE `dtPublish` IS NOT NULL AND `articles`.`id` != articleId
        ORDER BY `dtPublish` DESC;
    END IF;
END $$

DELIMITER ;


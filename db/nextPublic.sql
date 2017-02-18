-- 
--  NextPress Public (non-SSL) Procedures
--  Copyright (C) 2016 Lowadobe Web Services, LLC 
--  web: http://nextpress.online/
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
        SELECT `categories`.`id` INTO categoryId FROM `nextData`.`categories` 
            JOIN `nextData`.`article_categories` ON `categories`.`id` = `article_categories`.`idCategory`
            JOIN `nextData`.`articles` ON `article_categories`.`idArticle` = `articles`.`id`
            WHERE `categories`.`uri` = @mvp_uri AND `articles`.`dtPublish` IS NOT NULL LIMIT 1;
        IF categoryId > 0 THEN
            CALL `nextData`.`nextCategory`(categoryId);
            SET stop = 1;
        END IF;
    END IF;
    
    IF stop = 0 THEN
        SELECT `tags`.`id` INTO tagId FROM `nextData`.`tags` 
            JOIN `nextData`.`article_tags` ON `tags`.`id` = `article_tags`.`idTag`
            JOIN `nextData`.`articles` ON `article_tags`.`idArticle` = `articles`.`id`
            WHERE `tags`.`uri` = @mvp_uri AND `articles`.`dtPublish` IS NOT NULL LIMIT 1;
        IF tagId > 0 THEN
            CALL `nextData`.`nextTag`(tagId);
            SET stop = 1;
        END IF;
    END IF;
       
    IF stop = 0 THEN
        SET defaultUri = `nextData`.`getConfig`('Site','default_uri');
        SELECT `tpl` INTO pageTpl FROM `nextData`.`pages` 
            WHERE `uri` = defaultUri AND `published` > 0 LIMIT 1;
        IF pageTpl != '' THEN
            IF @mobile = 'Y' THEN
                SELECT `tpl` INTO pageTpl FROM `nextData`.`pages` 
                    WHERE `uri` = defaultUri AND `published` > 0 AND `mobile` = 1 LIMIT 1;
            END IF;
            SET @mvp_template = CONCAT('pages/', pageTpl);
            SET stop = 1;
        ELSE
            SELECT `id` INTO articleId FROM `nextData`.`articles` 
                WHERE `uri` = defaultUri AND `dtPublish` IS NOT NULL LIMIT 1;
            IF articleId > 0 THEN
                CALL `nextData`.`nextArticle`(articleId);
            ELSE
                SET @mvp_template = CONCAT('pages/', `nextData`.`getConfig`('Site','404Page'));
            END IF;
        END IF;
    END IF;
    
    SET @keywords = `nextData`.`getConfig`('Site','keywords');
    SET @domain = `nextData`.`getHost`(@mvp_headers);
    SELECT * FROM `nextData`.`dropins` WHERE `active` = 1;
END $$

DELIMITER ;

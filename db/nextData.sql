-- MySQL dump 10.13  Distrib 5.5.53, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: nextData
-- ------------------------------------------------------
-- Server version	5.5.53-0ubuntu0.14.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `admin_links`
--

DROP TABLE IF EXISTS `admin_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admin_links` (
  `id` bigint(20) NOT NULL,
  `uri` varchar(256) NOT NULL,
  `label` varchar(256) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_links`
--

LOCK TABLES `admin_links` WRITE;
/*!40000 ALTER TABLE `admin_links` DISABLE KEYS */;
INSERT INTO `admin_links` VALUES (10,'Dashboard','Dashboard'),(20,'Configuration','Configuration'),(30,'Pages','Pages'),(40,'Articles','Articles'),(50,'Media','Media'),(60,'Users','Users'),(70,'Categories','Categories'),(80,'ModerateComments','Moderate Comments'),(90,'WPImport','Import from WordPress'),(100,'MyProfile','My Profile'),(110,'Logout','Logout');
/*!40000 ALTER TABLE `admin_links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `article_categories`
--

DROP TABLE IF EXISTS `article_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `article_categories` (
  `idArticle` bigint(20) NOT NULL,
  `idCategory` bigint(20) NOT NULL,
  PRIMARY KEY (`idArticle`,`idCategory`),
  KEY `fk_category_article` (`idArticle`),
  KEY `fk_category` (`idCategory`),
  CONSTRAINT `fk_category` FOREIGN KEY (`idCategory`) REFERENCES `categories` (`id`),
  CONSTRAINT `fk_category_article` FOREIGN KEY (`idArticle`) REFERENCES `articles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `article_categories`
--

LOCK TABLES `article_categories` WRITE;
/*!40000 ALTER TABLE `article_categories` DISABLE KEYS */;
/*!40000 ALTER TABLE `article_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `article_tags`
--

DROP TABLE IF EXISTS `article_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `article_tags` (
  `idArticle` bigint(20) NOT NULL,
  `idTag` bigint(20) NOT NULL,
  PRIMARY KEY (`idArticle`,`idTag`),
  KEY `fk_tag_article` (`idArticle`),
  KEY `fk_tag` (`idTag`),
  CONSTRAINT `fk_tag` FOREIGN KEY (`idTag`) REFERENCES `tags` (`id`),
  CONSTRAINT `fk_tag_article` FOREIGN KEY (`idArticle`) REFERENCES `articles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `article_tags`
--

LOCK TABLES `article_tags` WRITE;
/*!40000 ALTER TABLE `article_tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `article_tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `articles`
--

DROP TABLE IF EXISTS `articles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `articles` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `idAuthor` bigint(20) NOT NULL,
  `idwp` bigint(20) DEFAULT NULL,
  `idCategory` bigint(20) DEFAULT NULL,
  `teasePic` varchar(1024) DEFAULT NULL,
  `content` text,
  `teaser` varchar(256) DEFAULT NULL,
  `title` varchar(256) DEFAULT NULL,
  `uri` varchar(256) DEFAULT NULL,
  `dtPublish` datetime DEFAULT NULL,
  `alreadyPublished` tinyint(4) DEFAULT '0',
  `numViews` bigint(20) unsigned DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_article_author` (`idAuthor`),
  CONSTRAINT `fk_article_author` FOREIGN KEY (`idAuthor`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `articles`
--

LOCK TABLES `articles` WRITE;
/*!40000 ALTER TABLE `articles` DISABLE KEYS */;
/*!40000 ALTER TABLE `articles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `categories` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `idParent` bigint(20) NOT NULL DEFAULT '1',
  `uri` varchar(1024) NOT NULL,
  `displayName` varchar(1024) NOT NULL,
  `ord` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_cat_parent` (`idParent`),
  CONSTRAINT `fk_cat_parent` FOREIGN KEY (`idParent`) REFERENCES `categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categories`
--

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES (1,1,'','',0);
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comment_notifications`
--

DROP TABLE IF EXISTS `comment_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment_notifications` (
  `idUser` bigint(20) NOT NULL,
  `idComment` bigint(20) unsigned NOT NULL,
  `notifyReplies` tinyint(4) DEFAULT '0',
  `notifyThreads` tinyint(4) DEFAULT '0',
  `notifyAsDigest` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`idUser`,`idComment`),
  KEY `fk_notify_user` (`idUser`),
  KEY `fk_notify_comment` (`idComment`),
  CONSTRAINT `fk_notify_comment` FOREIGN KEY (`idComment`) REFERENCES `comments` (`id`),
  CONSTRAINT `fk_notify_user` FOREIGN KEY (`idUser`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comment_notifications`
--

LOCK TABLES `comment_notifications` WRITE;
/*!40000 ALTER TABLE `comment_notifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `comment_notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comment_votes`
--

DROP TABLE IF EXISTS `comment_votes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment_votes` (
  `idComment` bigint(20) unsigned NOT NULL,
  `idUser` bigint(20) NOT NULL,
  `voteVal` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`idComment`,`idUser`),
  KEY `fk_vote_comment` (`idComment`),
  KEY `fk_vote_user` (`idUser`),
  CONSTRAINT `fk_vote_comment` FOREIGN KEY (`idComment`) REFERENCES `comments` (`id`),
  CONSTRAINT `fk_vote_user` FOREIGN KEY (`idUser`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comment_votes`
--

LOCK TABLES `comment_votes` WRITE;
/*!40000 ALTER TABLE `comment_votes` DISABLE KEYS */;
/*!40000 ALTER TABLE `comment_votes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idArticle` bigint(20) NOT NULL DEFAULT '0',
  `idCommenter` bigint(20) NOT NULL DEFAULT '0',
  `idParent` bigint(20) unsigned NOT NULL DEFAULT '0',
  `idTop` bigint(20) unsigned NOT NULL DEFAULT '0',
  `idwp` bigint(20) unsigned NOT NULL DEFAULT '0',
  `dtComment` datetime NOT NULL,
  `content` text NOT NULL,
  `tease` varchar(140) NOT NULL DEFAULT '',
  `approved` tinyint(4) NOT NULL DEFAULT '1',
  `spam` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_comment_article` (`idArticle`),
  KEY `fk_comment_user` (`idCommenter`),
  KEY `fk_comment_parent` (`idParent`),
  KEY `fk_comment_top` (`idTop`),
  CONSTRAINT `fk_comment_article` FOREIGN KEY (`idArticle`) REFERENCES `articles` (`id`),
  CONSTRAINT `fk_comment_parent` FOREIGN KEY (`idParent`) REFERENCES `comments` (`id`),
  CONSTRAINT `fk_comment_top` FOREIGN KEY (`idTop`) REFERENCES `comments` (`id`),
  CONSTRAINT `fk_comment_user` FOREIGN KEY (`idCommenter`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comments`
--

LOCK TABLES `comments` WRITE;
/*!40000 ALTER TABLE `comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `config`
--

DROP TABLE IF EXISTS `config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config` (
  `id` varchar(32) NOT NULL,
  `idSelect` varchar(32) NOT NULL DEFAULT '',
  `val` text,
  `section` varchar(128) NOT NULL,
  `description` text,
  `ord` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`,`section`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `config`
--

LOCK TABLES `config` WRITE;
/*!40000 ALTER TABLE `config` DISABLE KEYS */;
INSERT INTO `config` VALUES ('404Page','','404error','Site','404 error page for inactive, missing pages or broken links',9),('articleLayout','','nextArticle','Site','Article Layout Page',4),('articleLayoutMobile','','nextArticle_mobile','Site','Mobile version of Article Layout Page',5),('authorSelfPublish','yesno','No','Site','Authors may publish their own articles',13),('avatarResize','','-resize \'60x60>\'','Media','Avatar conversion directive (for ImageMagick convert)',22),('blacklist','','','Comments','Comments will be marked as spam if they contain any of these words, urls, or email addresses',50),('byDefault','yesno','Yes','Comments','Comments are open for articles by default - May be overridden for individual articles',40),('closeAfter','','14','Comments','Comments close after [number] days - set to 0 to disable',43),('date_format','','%b %D, %Y','Site','Date format',10),('defaultAvatar','','/media/avatars/defaultAvatar.png','Comments','Default Avatar shown with comments [relative uri - blank for none]',47),('default_uri','','','Site','Default uri (landing page or page not found)',3),('errorPage','','error','Site','System error page for internal errors',8),('guestUserId','','2','Comments','ID of User for Comments with no registration/log in',42),('image_formats','','|jpg|jpeg|png|gif|tiff|svg|','Media','Recognized image file extensions',23),('keywords','','','Site','Search engine keywords',12),('listLayout','','nextList','Site','Article List Layout Page',6),('listLayoutMobile','','nextList_mobile','Site','Mobile version of Article List Layout Page',7),('loginOnly','yesno','No','Comments','Commenters must register/log in to comment',41),('mediaResize','','-resize \'1024x600>\'','Media','Image conversion directive (for ImageMagick convert)',20),('mediaThumbsize','','-resize \'120x90>\'','Media','Thumbnail conversion directive (for ImageMagick convert)',21),('modAll','yesno','No','Comments','All comments will be held for moderation',51),('modlist','','','Comments','Comments will be held for moderation if they contain any of these words, urls, or email addresses',53),('modlistNumlinks','','','Comments','Comments will be held for moderation if they contain more than [number] links',54),('modPrevApproved','yesno','Yes','Comments','Previously approved Commenters will be automatically approved',52),('notifications','yesno','Yes','Site','Make notifications of new articles available',14),('notifyAdmin','yesno','No','Comments','Email Administrators when comments are submitted',57),('notifyAdminHeld','yesno','No','Comments','Email Administrators when comments are held for moderation',58),('notifyAll','yesno','Yes','Comments','Email Article Authors when comments are submitted',55),('notifyHeld','yesno','No','Comments','Email Moderators when comments are held for moderation',56),('registration','yesno','No','Site','Allow Guests to Register (primarily for new article notification)',15),('showAvatars','yesno','Yes','Comments','User Avatars shown with comments',46),('tagline','','A NextPress Site','Site','Site Tagline',11),('threadDepth','','3','Comments','Reply depth to display in threaded format',45),('threaded','yesno','No','Comments','Display comments in threaded format',44),('tplroot','','/var/www/templates','Site','The absolute path of the template directory',2),('voting','yesno','Yes','Comments','Allow up/down voting on comments',48),('votingLogin','yesno','Yes','Comments','Require registration/log in for up/down voting on comments',49),('webroot','','/var/www/public','Site','The absolute path of the web directory',1);
/*!40000 ALTER TABLE `config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `config_selection`
--

DROP TABLE IF EXISTS `config_selection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_selection` (
  `idGroup` varchar(32) NOT NULL,
  `val` varchar(32) NOT NULL,
  PRIMARY KEY (`idGroup`,`val`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `config_selection`
--

LOCK TABLES `config_selection` WRITE;
/*!40000 ALTER TABLE `config_selection` DISABLE KEYS */;
INSERT INTO `config_selection` VALUES ('yesno','No'),('yesno','Yes');
/*!40000 ALTER TABLE `config_selection` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dropins`
--

DROP TABLE IF EXISTS `dropins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dropins` (
  `id` varchar(32) NOT NULL,
  `tpl` varchar(1024) NOT NULL,
  `img` varchar(1024) NOT NULL,
  `css` varchar(1024) DEFAULT NULL,
  `js` varchar(1024) DEFAULT NULL,
  `active` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dropins`
--

LOCK TABLES `dropins` WRITE;
/*!40000 ALTER TABLE `dropins` DISABLE KEYS */;
/*!40000 ALTER TABLE `dropins` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mail_errors`
--

DROP TABLE IF EXISTS `mail_errors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mail_errors` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `theDate` datetime DEFAULT NULL,
  `errors` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mail_errors`
--

LOCK TABLES `mail_errors` WRITE;
/*!40000 ALTER TABLE `mail_errors` DISABLE KEYS */;
/*!40000 ALTER TABLE `mail_errors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `media`
--

DROP TABLE IF EXISTS `media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `media` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `idAuthor` bigint(20) NOT NULL,
  `uri` varchar(1024) NOT NULL,
  `thumb` varchar(1024) DEFAULT NULL,
  `isImage` tinyint(4) DEFAULT NULL,
  `dtAdded` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_media_author` (`idAuthor`),
  CONSTRAINT `fk_media_author` FOREIGN KEY (`idAuthor`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `media`
--

LOCK TABLES `media` WRITE;
/*!40000 ALTER TABLE `media` DISABLE KEYS */;
/*!40000 ALTER TABLE `media` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pages`
--

DROP TABLE IF EXISTS `pages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pages` (
  `uri` varchar(512) NOT NULL,
  `tpl` varchar(1024) NOT NULL,
  `mobile` tinyint(4) NOT NULL DEFAULT '0',
  `published` tinyint(4) DEFAULT '0',
  `content` text,
  PRIMARY KEY (`uri`,`mobile`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pages`
--

LOCK TABLES `pages` WRITE;
/*!40000 ALTER TABLE `pages` DISABLE KEYS */;
INSERT INTO `pages` VALUES ('','landingPage',0,1,''),('','landingPage_mobile',1,0,''),('404','404Page',0,1,'<div style=\"margin-left: 50px;\">\n    <h1>Page Not Found</h1>\n    <p>The page you have requested is not available</p>\n    <p>Please <a href=\"/\">click here</a> for the Home Page</p>\n</div>\n'),('err','errorPage',0,1,'<div style=\"margin-left: 50px;\">\n    <h1>System Error</h1>\n    <p>The Administrator has been notified.</p>\n    <p>Please <a href=\"/\">click here</a> for the Home Page</p>\n</div>\n'),('nextarticle','nextArticle',0,1,''),('nextarticle','nextArticle_mobile',1,0,''),('nextlist','nextList',0,1,''),('nextlist','nextList_mobile',1,0,'');
/*!40000 ALTER TABLE `pages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role_admin_links`
--

DROP TABLE IF EXISTS `role_admin_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `role_admin_links` (
  `idRole` bigint(20) NOT NULL,
  `idLink` bigint(20) NOT NULL,
  PRIMARY KEY (`idRole`,`idLink`),
  KEY `fk_ral_role` (`idRole`),
  KEY `fk_ral_link` (`idLink`),
  CONSTRAINT `fk_ral_link` FOREIGN KEY (`idLink`) REFERENCES `admin_links` (`id`),
  CONSTRAINT `fk_ral_role` FOREIGN KEY (`idRole`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role_admin_links`
--

LOCK TABLES `role_admin_links` WRITE;
/*!40000 ALTER TABLE `role_admin_links` DISABLE KEYS */;
INSERT INTO `role_admin_links` VALUES (1,10),(1,20),(1,30),(1,50),(1,60),(1,70),(1,90),(1,100),(1,110),(2,10),(2,40),(2,50),(2,100),(2,110),(3,10),(3,40),(3,100),(3,110),(4,10),(4,80),(4,100),(4,110),(5,10),(5,100),(5,110);
/*!40000 ALTER TABLE `role_admin_links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `label` varchar(256) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Admin'),(2,'Editor'),(3,'Author'),(4,'Moderator'),(5,'Commenter');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` varchar(32) NOT NULL,
  `idUser` bigint(20) DEFAULT NULL,
  `ipAddress` varchar(128) DEFAULT NULL,
  `redirect` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_session_user` (`idUser`),
  CONSTRAINT `fk_session_user` FOREIGN KEY (`idUser`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tags` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uri` varchar(1024) NOT NULL,
  `displayName` varchar(1024) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tags`
--

LOCK TABLES `tags` WRITE;
/*!40000 ALTER TABLE `tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_roles`
--

DROP TABLE IF EXISTS `user_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_roles` (
  `idUser` bigint(20) NOT NULL,
  `idRole` bigint(20) NOT NULL,
  PRIMARY KEY (`idUser`,`idRole`),
  KEY `fk_ur_user` (`idUser`),
  KEY `fk_ur_role` (`idRole`),
  CONSTRAINT `fk_ur_role` FOREIGN KEY (`idRole`) REFERENCES `roles` (`id`),
  CONSTRAINT `fk_ur_user` FOREIGN KEY (`idUser`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_roles`
--

LOCK TABLES `user_roles` WRITE;
/*!40000 ALTER TABLE `user_roles` DISABLE KEYS */;
INSERT INTO `user_roles` VALUES (1,1),(2,5);
/*!40000 ALTER TABLE `user_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `password` varchar(512) DEFAULT NULL,
  `verifyCode` varchar(32) DEFAULT NULL,
  `displayName` varchar(1024) DEFAULT NULL,
  `email` varchar(1024) DEFAULT NULL,
  `url` varchar(1024) DEFAULT NULL,
  `avatarUri` varchar(1024) DEFAULT NULL,
  `prohibited` tinyint(4) DEFAULT '0',
  `notifyArticles` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'982f630ae2e1e67188b5ae7686f34fbd7a3e6db23e92f40a5080d29a1cdf8efeb68c90e9eaf6f24c2f903f72e1778edd957560ff867c07adb4791c1be1c1f8c8',NULL,'Administrator','change.me@nextpress.org',NULL,NULL,0,0),(2,'982f630ae2e1e67188b5ae7686f34fbd7a3e6db23e92f40a5080d29a1cdf8efeb68c90e9eaf6f24c2f903f72e1778edd957560ff867c07adb4791c1be1c1f8c8',NULL,'Guest Commenter',NULL,NULL,NULL,0,0);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-03-11 15:21:03

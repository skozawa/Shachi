-- MySQL dump 10.13  Distrib 5.5.40, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: shachi_old
-- ------------------------------------------------------
-- Server version	5.5.40-0ubuntu0.14.04.1

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
-- Table structure for table `annotators`
--

DROP TABLE IF EXISTS `annotators`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `annotators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  `mail` text NOT NULL,
  `organization` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=74 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `languages`
--

DROP TABLE IF EXISTS `languages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `languages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(3) NOT NULL DEFAULT '',
  `name` varchar(100) NOT NULL DEFAULT '',
  `area` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=7643 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `options`
--

DROP TABLE IF EXISTS `options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `class` varchar(100) NOT NULL DEFAULT '',
  `value` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=179 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resources`
--

DROP TABLE IF EXISTS `resources`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resources` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shachi_id` varchar(20) NOT NULL DEFAULT '',
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `modified` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `is_public` tinyint(1) NOT NULL DEFAULT '1',
  `annotator` int(11) NOT NULL DEFAULT '1',
  `status` varchar(20) NOT NULL DEFAULT 'new',
  `title` text NOT NULL,
  `title_alternative` text NOT NULL,
  `creator` text NOT NULL,
  `subject` text NOT NULL,
  `subject_linguisticField` text NOT NULL,
  `subject_monoMultilingual` text NOT NULL,
  `subject_resourceSubject` text NOT NULL,
  `description` text NOT NULL,
  `description_price` text NOT NULL,
  `description_language` text NOT NULL,
  `description_input_device` text NOT NULL,
  `description_input_environment` text NOT NULL,
  `description_speaking_style` text,
  `description_speech_mode` text,
  `description_sampling_rate` text,
  `description_additional_data` text,
  `publisher` text NOT NULL,
  `contributor` text NOT NULL,
  `contributor_motherTongue` text NOT NULL,
  `contributor_intonation` text NOT NULL,
  `contributor_level` text NOT NULL,
  `contributor_age` text NOT NULL,
  `contributor_gender` text NOT NULL,
  `contributor_author_motherTongue` text NOT NULL,
  `contributor_author_dialect` text,
  `contributor_author_level` text NOT NULL,
  `contributor_author_age` text NOT NULL,
  `contributor_author_gender` text NOT NULL,
  `contributor_speaker_motherTongue` text NOT NULL,
  `contributor_speaker_dialect` text,
  `contributor_speaker_level` text NOT NULL,
  `contributor_speaker_age` text NOT NULL,
  `contributor_speaker_gender` text NOT NULL,
  `contributor_speaker_number` text,
  `date_created` text NOT NULL,
  `date_issued` text NOT NULL,
  `date_modified` text NOT NULL,
  `type` text NOT NULL,
  `type_discourseType` text NOT NULL,
  `type_linguisticType` text NOT NULL,
  `type_purpose` text NOT NULL,
  `type_style` text NOT NULL,
  `type_form` text NOT NULL,
  `type_sentence` text NOT NULL,
  `type_annotation` text NOT NULL,
  `type_annotationSample` text NOT NULL,
  `type_sample` text NOT NULL,
  `format_extent` text NOT NULL,
  `format_medium` text NOT NULL,
  `format_encoding` text NOT NULL,
  `format_markup` text NOT NULL,
  `format_functionality` text NOT NULL,
  `identifier` text NOT NULL,
  `source` text NOT NULL,
  `language` text NOT NULL,
  `language_area` text NOT NULL,
  `relation` text NOT NULL,
  `relation_utilization` text NOT NULL,
  `coverage_temporal` text NOT NULL,
  `coverage_spacial` text NOT NULL,
  `rights` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4392 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scheme`
--

DROP TABLE IF EXISTS `scheme`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scheme` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT '',
  `label` varchar(100) NOT NULL DEFAULT '',
  `multi_value` varchar(100) NOT NULL DEFAULT '',
  `type` varchar(100) NOT NULL DEFAULT '',
  `options` varchar(100) NOT NULL DEFAULT '',
  `color` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=10001 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `title_list`
--

DROP TABLE IF EXISTS `title_list`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `title_list` (
  `id` int(11) NOT NULL,
  `title` text NOT NULL,
  `MID` varchar(3) NOT NULL,
  `common_title` text NOT NULL,
  `candidate1` text NOT NULL,
  `candidate2` text NOT NULL,
  `candidate3` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-01-17 17:11:31

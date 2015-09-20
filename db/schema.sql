DROP TABLE IF EXISTS `annotator`;
CREATE TABLE `annotator` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  `mail` text NOT NULL,
  `organization` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `language`;
CREATE TABLE `language` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(3) NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,  -- collate for umlaut, metadata_value.value
  `area` varchar(100) NOT NULL,
  `value_id` bigint NOT NULL DEFAULT 0, -- metadata_value.id
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_code` (`code`),
  UNIQUE KEY `idx_value_id` (`value_id`),
  UNIQUE KEY `idx_name` (`name`),
  KEY (`name`),
  KEY (`area`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `metadata`;
CREATE TABLE `metadata` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `label` varchar(100) NOT NULL,
  `order_num` int NOT NULL,
  `shown` boolean NOT NULL DEFAULT true,
  `multi_value` boolean NOT NULL DEFAULT false,
  `input_type` enum('text', 'textarea', 'select', 'select_only', 'relation', 'language', 'date', 'range') NOT NULL DEFAULT 'text',
  `value_type` varchar(100) NOT NULL, -- metadata_value.value_type
  `color` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_name` (`name`),
  KEY `idx_shown_order` (`shown`, `order_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `metadata_value`;
CREATE TABLE `metadata_value` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `value_type` varchar(100) NOT NULL, -- metadata.value_type
  `value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL, -- collate for umlaut
  PRIMARY KEY(`id`),
  UNIQUE KEY `idx_type_value` (`value_type`, `value`),
  KEY `idx_value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `resource`;
CREATE TABLE `resource` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `shachi_id` varchar(20) NOT NULL,
  `status` enum('public', 'limited_by_ELRA', 'limited_by_LDC', 'private') NOT NULL DEFAULT 'public',
  `annotator_id` bigint NOT NULL DEFAULT 1,
  `edit_status` enum('new', 'editing', 'complete', 'pending', 'revised', 'proofed') NOT NULL DEFAULT 'new', 
  `created` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',
  `modified` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  KEY `idx_shachi_id` (`shachi_id`),
  KEY `idx_status_created` (`status`, `created`),
  KEY `idx_created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `resource_metadata`;
CREATE TABLE `resource_metadata` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `resource_id` bigint NOT NULL,
  `metadata_id` bigint NOT NULL,
  `language_id` bigint NOT NULL,
  `value_id` bigint NOT NULL DEFAULT 0,
  `content` text,
  `description` text,
  PRIMARY KEY (`id`),
  KEY `idx_resource_language` (`resource_id`, `language_id`),
  KEY `idx_metadata_value` (`metadata_id`, `value_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `engagedsnake-scores` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `player_name` VARCHAR(32) NOT NULL,
  `score` INT UNSIGNED NOT NULL DEFAULT 0,
  `level_ended` INT UNSIGNED NOT NULL DEFAULT 1,
  `victory` TINYINT(1) NOT NULL DEFAULT 0,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `engagedsnake-scores_score_idx` (`score` DESC, `created_at` ASC),
  KEY `engagedsnake-scores_victory_idx` (`victory`, `score` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

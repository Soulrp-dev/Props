-- dn_collections schema (MySQL/MariaDB) - Fase 1 + fundamentos da Fase 3
-- Compatível com oxmysql
-- Execute no seu database do servidor FiveM.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- ===============================
-- TABELAS PRINCIPAIS (FASE 1)
-- ===============================

-- Tabela de propriedade de itens de coleção/insígnias
CREATE TABLE IF NOT EXISTS `dnc_collections_ownership` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64) NOT NULL,           -- license/steam/char id (ajuste conforme sua base)
  `item_key` VARCHAR(64) NOT NULL,             -- chave do item (ex.: 'plush_teddy')
  `qty` INT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_owner_item` (`identifier`,`item_key`),
  KEY `idx_identifier` (`identifier`),
  KEY `idx_item_key` (`item_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insígnia em destaque do jogador (mostrada no inventário)
CREATE TABLE IF NOT EXISTS `dnc_collections_badge` (
  `identifier` VARCHAR(64) NOT NULL,
  `item_key` VARCHAR(64) DEFAULT NULL,         -- deve ser um item do tipo 'badge'
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===============================
-- OPCIONAL (CATÁLOGO NO DB)
-- Você pode manter o catálogo no arquivo Lua,
-- mas se preferir migrar para o DB, use a tabela abaixo.
-- ===============================
CREATE TABLE IF NOT EXISTS `dnc_collections_catalog` (
  `item_key` VARCHAR(64) NOT NULL,             -- PK
  `name` VARCHAR(80) NOT NULL,
  `series` VARCHAR(80) NOT NULL,               -- ex.: 'Pelúcias', 'Insígnias', 'Hello Kitty'
  `rarity` VARCHAR(32) NOT NULL,               -- ex.: 'Comum','Rara','Épica','Lendária','VIP'
  `type` ENUM('collection','badge') NOT NULL,  -- tipo do item
  `prop` VARCHAR(80) DEFAULT NULL,             -- nome do model para segurar/mostrar
  `icon` VARCHAR(120) DEFAULT NULL,            -- caminho/arquivo de ícone (se usar)
  `tradable` TINYINT(1) NOT NULL DEFAULT 1,    -- 1 = trocável; 0 = não trocável
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`item_key`),
  KEY `idx_series` (`series`),
  KEY `idx_rarity` (`rarity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===============================
-- BASE PARA TROCAS (FASE 3) - opcional agora
-- ===============================
-- Registro de trades
CREATE TABLE IF NOT EXISTS `dnc_collections_trades` (
  `trade_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `initiator_identifier` VARCHAR(64) NOT NULL,
  `target_identifier` VARCHAR(64) NOT NULL,
  `state` ENUM('pending','accepted','cancelled','expired') NOT NULL DEFAULT 'pending',
  `initiator_offer` JSON DEFAULT NULL,  -- lista de {item_key, qty}
  `target_offer` JSON DEFAULT NULL,     -- lista de {item_key, qty}
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`trade_id`),
  KEY `idx_state` (`state`),
  KEY `idx_initiator` (`initiator_identifier`),
  KEY `idx_target` (`target_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Locks de itens durante um trade (evita “sumir” itens em corridas de condição)
CREATE TABLE IF NOT EXISTS `dnc_collections_locks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `trade_id` BIGINT UNSIGNED NOT NULL,
  `identifier` VARCHAR(64) NOT NULL,
  `item_key` VARCHAR(64) NOT NULL,
  `qty_locked` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_trade` (`trade_id`),
  KEY `idx_identifier` (`identifier`),
  KEY `idx_item_key` (`item_key`),
  CONSTRAINT `fk_locks_trade` FOREIGN KEY (`trade_id`) REFERENCES `dnc_collections_trades`(`trade_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===============================
-- SEEDS DE TESTE (opcionais)
-- ===============================
-- Exemplos de catálogo (apague se não usar o catálogo no DB)
INSERT IGNORE INTO `dnc_collections_catalog` (`item_key`,`name`,`series`,`rarity`,`type`,`prop`,`icon`,`tradable`)
VALUES
('plush_teddy','Urso de Pelúcia','Pelúcias','Comum','collection','prop_teddy_bear','teddy.png',1),
('plush_dragon','Dragão Vermelho','Pelúcias','Épica','collection','prop_dragon','dragon.png',1),
('badge_vip','Insígnia VIP','Insígnias','VIP','badge','prop_ld_wallet_01','vip.png',0),
('badge_hello','Hello Kitty','Hello Kitty','Rara','badge','prop_ld_wallet_01','hello.png',1);

-- Storify – Database schema
-- Database: MySQL (InnoDB), hosted on Plesk
-- Created: cikle, 2026

-- ─────────────────────────────────────────────────
-- Table: locations
-- ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `locations` (
  `id`          INT           NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(255)  NOT NULL,
  `description` TEXT          NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────
-- Table: items (inventory)
-- ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `items` (
  `id`          INT           NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(255)  NOT NULL,
  `description` TEXT          NOT NULL,
  `category`    VARCHAR(100)  NOT NULL,
  `barcode`     VARCHAR(100)  NULL,
  `quantity`    INT           NOT NULL DEFAULT 0,
  `location_id` INT           NOT NULL,
  `expiry_date` DATE          NULL DEFAULT NULL COMMENT 'Expiration date of the item (optional)',
  PRIMARY KEY (`id`),
  -- Foreign key: each item is assigned to a location
  CONSTRAINT `fk_items_location`
    FOREIGN KEY (`location_id`)
    REFERENCES `locations` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  -- Index on location_id for efficient JOIN queries
  INDEX `idx_location_id` (`location_id`),
  -- Index on category for filter queries
  INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────
-- Sample data (optional – for testing)
-- ─────────────────────────────────────────────────
INSERT INTO `locations` (`name`, `description`) VALUES
  ('Warehouse A', 'Main warehouse, ground floor'),
  ('Office',      'Office supplies and electronics'),
  ('Workshop',    'Tools and spare parts');

INSERT INTO `items` (`name`, `description`, `category`, `barcode`, `quantity`, `location_id`) VALUES
  ('Laptop Dell XPS',   'Business laptop, 15 inch',    'Electronics', '1234567890123', 3,  2),
  ('Office Chair',      'Ergonomic office chair',       'Furniture',   NULL,             7,  2),
  ('Screwdriver',       'Phillips PH2',                 'Tools',       '9876543210987', 2,  3),
  ('USB Hub 7-Port',    '7-Port USB 3.0 Hub',           'Electronics', '1111111111111', 4,  2),
  ('Binder A4',         'Blue binder, 8cm spine',       'Stationery',  '2222222222222', 12, 1),
  ('Hammer',            'Steel hammer, 300g',           'Tools',       NULL,             1,  3);

-- ─────────────────────────────────────────────────
-- Migration: add expiry_date column to existing items table
-- Safe to run on an existing DB (additive, no data loss)
-- ─────────────────────────────────────────────────
-- ALTER TABLE `items`
--   ADD COLUMN `expiry_date` DATE NULL DEFAULT NULL
--     COMMENT 'Expiration date of the item (optional)',
--   ADD INDEX `idx_expiry_date` (`expiry_date`);
-- (Commented out – only run if the table already exists)

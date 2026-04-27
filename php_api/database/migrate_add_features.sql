-- Storify – Migration: add new feature columns
-- Run this on an existing database to add all new feature columns.
-- Safe to run multiple times only if columns do not already exist.

ALTER TABLE `items`
  ADD COLUMN `unit`               VARCHAR(50)   NULL DEFAULT NULL
    COMMENT 'Unit of measure: Gramm | Packung | Rollen | Stück | Flaschen | Dosen | Tuben',
  ADD COLUMN `critical_threshold` INT           NULL DEFAULT NULL
    COMMENT 'Per-item low-stock threshold (overrides global kLowStockThreshold)',
  ADD COLUMN `warning_days`       INT           NULL DEFAULT NULL
    COMMENT 'Days before expiry to show warning (overrides global 7-day default)',
  ADD COLUMN `pack_size`          INT           NULL DEFAULT 1
    COMMENT 'Number of sub-units per pack (e.g. 12 rolls per Packung)',
  ADD COLUMN `photo_url`          VARCHAR(500)  NULL DEFAULT NULL
    COMMENT 'Relative path to uploaded photo, e.g. uploads/item_42_123.jpg',
  MODIFY COLUMN `description` TEXT NULL,
  MODIFY COLUMN `category`    VARCHAR(100) NULL;

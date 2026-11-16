-- Replace placeholders; execute as DBA. Restrict host and rotate password.
CREATE USER 'cms_app'@'localhost' IDENTIFIED BY 'REPLACE_WITH_LONG_RANDOM_SECRET';
GRANT SELECT, INSERT, UPDATE, DELETE ON cms_database.* TO 'cms_app'@'localhost';
FLUSH PRIVILEGES;
-- Verify: SHOW GRANTS FOR 'cms_app'@'localhost';

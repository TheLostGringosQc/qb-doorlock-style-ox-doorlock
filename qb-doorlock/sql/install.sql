-- ================================
-- INSTALLATION SQL - QB-DOORLOCK
-- sql/install.sql
-- Installation initiale pour nouveaux serveurs
-- ================================

-- ================================
-- CRÉATION DES TABLES PRINCIPALES
-- ================================

-- Table principale pour les états des portes
CREATE TABLE IF NOT EXISTS `doorlocks` (
    `id` VARCHAR(50) NOT NULL COMMENT 'Identifiant unique de la porte',
    `locked` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'État verrouillé (1) ou déverrouillé (0)',
    `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Dernière mise à jour',
    `last_user` VARCHAR(50) DEFAULT NULL COMMENT 'Dernier utilisateur (CitizenID)',
    `property_type` VARCHAR(50) DEFAULT 'standard' COMMENT 'Type de propriété (house, apartment, office, etc.)',
    `door_type` VARCHAR(50) DEFAULT 'main' COMMENT 'Type de porte (main, garage, office, etc.)',
    `property_id` VARCHAR(100) DEFAULT NULL COMMENT 'ID de la propriété (pour PS-Housing)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date de création',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Dernière modification',
    
    PRIMARY KEY (`id`),
    INDEX `idx_property_type` (`property_type`),
    INDEX `idx_door_type` (`door_type`),
    INDEX `idx_property_id` (`property_id`),
    INDEX `idx_last_updated` (`last_updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table principale des états de portes QB-Doorlock';

-- Table des logs d'activité des portes
CREATE TABLE IF NOT EXISTS `doorlock_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `door_id` VARCHAR(50) NOT NULL COMMENT 'ID de la porte',
    `citizenid` VARCHAR(50) NOT NULL COMMENT 'CitizenID du joueur',
    `action` ENUM('lock','unlock') NOT NULL COMMENT 'Action effectuée',
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Horodatage',
    `job` VARCHAR(50) DEFAULT NULL COMMENT 'Job du joueur',
    `grade` INT(11) DEFAULT NULL COMMENT 'Grade du joueur',
    `method` VARCHAR(50) DEFAULT 'manual' COMMENT 'Méthode d\'accès (manual, keycard, code, etc.)',
    `details` TEXT DEFAULT NULL COMMENT 'Détails supplémentaires',
    
    PRIMARY KEY (`id`),
    INDEX `idx_door_id` (`door_id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Logs d\'activité des portes';

-- Table des logs de sécurité avancés
CREATE TABLE IF NOT EXISTS `doorlock_security_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `door_id` VARCHAR(50) NOT NULL COMMENT 'ID de la porte',
    `citizenid` VARCHAR(50) NOT NULL COMMENT 'CitizenID du joueur',
    `event_type` ENUM(
        'alarm', 
        'breach', 
        'maintenance', 
        'emergency', 
        'access_granted', 
        'access_denied', 
        'suspicious_activity', 
        'alarm_deactivated',
        'multi_key_access',
        'code_access',
        'repair'
    ) NOT NULL COMMENT 'Type d\'événement de sécurité',
    `coordinates` JSON DEFAULT NULL COMMENT 'Coordonnées de l\'événement',
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Horodatage de l\'événement',
    `details` TEXT DEFAULT NULL COMMENT 'Détails supplémentaires',
    `severity` ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium' COMMENT 'Niveau de gravité',
    `resolved` BOOLEAN DEFAULT FALSE COMMENT 'Événement résolu',
    `resolved_by` VARCHAR(50) DEFAULT NULL COMMENT 'Résolu par (CitizenID)',
    `resolved_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Date de résolution',
    
    INDEX `idx_door_id` (`door_id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_event_type` (`event_type`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_severity` (`severity`),
    INDEX `idx_resolved` (`resolved`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Logs de sécurité avancés';

-- Table de maintenance des portes
CREATE TABLE IF NOT EXISTS `doorlock_maintenance` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `door_id` VARCHAR(50) NOT NULL COMMENT 'ID de la porte',
    `maintenance_type` ENUM(
        'scheduled', 
        'emergency', 
        'repair', 
        'inspection', 
        'upgrade'
    ) DEFAULT 'scheduled' COMMENT 'Type de maintenance',
    `start_time` TIMESTAMP NOT NULL COMMENT 'Heure de début prévue',
    `end_time` TIMESTAMP NOT NULL COMMENT 'Heure de fin prévue',
    `actual_start` TIMESTAMP NULL DEFAULT NULL COMMENT 'Heure de début réelle',
    `actual_end` TIMESTAMP NULL DEFAULT NULL COMMENT 'Heure de fin réelle',
    `reason` TEXT NOT NULL COMMENT 'Raison de la maintenance',
    `description` TEXT DEFAULT NULL COMMENT 'Description détaillée',
    `scheduled_by` VARCHAR(50) NOT NULL COMMENT 'Programmé par (CitizenID)',
    `assigned_to` VARCHAR(50) DEFAULT NULL COMMENT 'Assigné à (CitizenID)',
    `status` ENUM(
        'scheduled', 
        'in_progress', 
        'completed', 
        'cancelled', 
        'failed'
    ) DEFAULT 'scheduled' COMMENT 'Statut de la maintenance',
    `completed` BOOLEAN DEFAULT FALSE COMMENT 'Maintenance terminée',
    `cost` DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Coût de la maintenance',
    `notes` TEXT DEFAULT NULL COMMENT 'Notes supplémentaires',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_door_id` (`door_id`),
    INDEX `idx_maintenance_type` (`maintenance_type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_scheduled_by` (`scheduled_by`),
    INDEX `idx_start_time` (`start_time`),
    INDEX `idx_completed` (`completed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Planning et historique de maintenance';

-- Table pour les clés de propriétés (PS-Housing v2.0)
CREATE TABLE IF NOT EXISTS `doorlock_property_keys` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_id` VARCHAR(100) NOT NULL COMMENT 'ID de la propriété',
    `citizenid` VARCHAR(50) NOT NULL COMMENT 'CitizenID du détenteur de clé',
    `key_type` ENUM(
        'owner', 
        'tenant', 
        'manager', 
        'temporary', 
        'guest', 
        'service'
    ) NOT NULL COMMENT 'Type de clé/accès',
    `permissions` JSON DEFAULT NULL COMMENT 'Permissions spécifiques (portes accessibles)',
    `expires_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Date d\'expiration (pour clés temporaires)',
    `granted_by` VARCHAR(50) NOT NULL COMMENT 'Accordé par (CitizenID)',
    `granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date d\'octroi',
    `revoked` BOOLEAN DEFAULT FALSE COMMENT 'Clé révoquée',
    `revoked_by` VARCHAR(50) DEFAULT NULL COMMENT 'Révoquée par (CitizenID)',
    `revoked_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Date de révocation',
    `last_used` TIMESTAMP NULL DEFAULT NULL COMMENT 'Dernière utilisation',
    `use_count` INT DEFAULT 0 COMMENT 'Nombre d\'utilisations',
    `notes` TEXT DEFAULT NULL COMMENT 'Notes supplémentaires',
    
    INDEX `idx_property_id` (`property_id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_key_type` (`key_type`),
    INDEX `idx_expires_at` (`expires_at`),
    INDEX `idx_granted_by` (`granted_by`),
    INDEX `idx_revoked` (`revoked`),
    UNIQUE KEY `unique_active_key` (`property_id`, `citizenid`, `key_type`, `revoked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Gestion des clés de propriétés (PS-Housing v2.0)';

-- Table pour l'historique des migrations
CREATE TABLE IF NOT EXISTS `doorlock_migrations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `version` VARCHAR(20) NOT NULL COMMENT 'Version de la migration',
    `description` TEXT COMMENT 'Description de la migration',
    `executed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date d\'exécution',
    `execution_time_ms` INT DEFAULT 0 COMMENT 'Temps d\'exécution en millisecondes',
    `success` BOOLEAN DEFAULT TRUE COMMENT 'Migration réussie',
    `error_message` TEXT DEFAULT NULL COMMENT 'Message d\'erreur si échec',
    
    UNIQUE KEY `unique_version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historique des migrations QB-Doorlock';

-- ================================
-- INSERTION DES DONNÉES INITIALES
-- ================================

-- Portes par défaut pour un serveur QBCore standard
INSERT INTO `doorlocks` (`id`, `locked`, `property_type`, `door_type`) VALUES 
-- LSPD
('lspd_main_entrance', 1, 'government', 'main'),
('lspd_cells_main', 1, 'government', 'cell'),
('lspd_evidence', 1, 'government', 'evidence'),

-- Hôpital Pillbox
('pillbox_main', 1, 'medical', 'main'),
('pillbox_surgery', 1, 'medical', 'surgery'),

-- Garage Bennys
('bennys_main', 0, 'business', 'main'),

-- Banque Fleeca
('fleeca_vault_1', 1, 'bank', 'vault'),

-- Entrepôt sécurisé
('secure_warehouse', 1, 'government', 'secure')

ON DUPLICATE KEY UPDATE 
    `locked` = VALUES(`locked`),
    `property_type` = VALUES(`property_type`),
    `door_type` = VALUES(`door_type`);

-- Enregistrer cette installation
INSERT INTO `doorlock_migrations` (`version`, `description`, `execution_time_ms`) 
VALUES ('1.0.0', 'Installation initiale QB-Doorlock', 0)
ON DUPLICATE KEY UPDATE 
    `executed_at` = CURRENT_TIMESTAMP,
    `description` = VALUES(`description`);

-- ================================
-- VUES POUR FACILITER LES REQUÊTES
-- ================================

-- Vue pour les statistiques de sécurité
CREATE OR REPLACE VIEW `doorlock_security_stats` AS
SELECT 
    door_id,
    COUNT(*) as total_events,
    COUNT(CASE WHEN event_type = 'access_denied' THEN 1 END) as denied_attempts,
    COUNT(CASE WHEN event_type = 'alarm' THEN 1 END) as alarms_triggered,
    COUNT(CASE WHEN severity = 'critical' THEN 1 END) as critical_events,
    MAX(timestamp) as last_event,
    COUNT(CASE WHEN timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 END) as events_24h
FROM doorlock_security_logs 
GROUP BY door_id;

-- Vue pour les maintenances en cours
CREATE OR REPLACE VIEW `doorlock_active_maintenance` AS
SELECT 
    m.*,
    d.property_type,
    d.property_id,
    TIMESTAMPDIFF(MINUTE, m.start_time, COALESCE(m.actual_end, NOW())) as duration_minutes
FROM doorlock_maintenance m
LEFT JOIN doorlocks d ON m.door_id = d.id
WHERE m.status IN ('scheduled', 'in_progress');

-- Vue pour les clés actives par propriété
CREATE OR REPLACE VIEW `doorlock_active_keys` AS
SELECT 
    pk.*,
    CASE 
        WHEN pk.expires_at IS NOT NULL AND pk.expires_at < NOW() THEN 'expired'
        WHEN pk.revoked = 1 THEN 'revoked'
        ELSE 'active'
    END as key_status
FROM doorlock_property_keys pk
WHERE pk.revoked = 0;

-- ================================
-- PROCÉDURES STOCKÉES UTILES
-- ================================

-- Procédure pour nettoyer les anciens logs
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS `CleanupOldLogs`(IN days_to_keep INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Nettoyer les logs de sécurité anciens
    DELETE FROM doorlock_security_logs 
    WHERE timestamp < DATE_SUB(NOW(), INTERVAL days_to_keep DAY)
    AND resolved = 1;
    
    -- Nettoyer les logs d'accès anciens
    DELETE FROM doorlock_logs 
    WHERE timestamp < DATE_SUB(NOW(), INTERVAL days_to_keep DAY);
    
    -- Nettoyer les maintenances terminées anciennes
    DELETE FROM doorlock_maintenance 
    WHERE completed = 1 
    AND updated_at < DATE_SUB(NOW(), INTERVAL days_to_keep DAY);
    
    COMMIT;
    
    SELECT CONCAT('Nettoyage terminé: logs de plus de ', days_to_keep, ' jours supprimés') as message;
END //
DELIMITER ;

-- Procédure pour révoquer toutes les clés d'une propriété
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS `RevokeAllPropertyKeys`(IN prop_id VARCHAR(100), IN revoked_by_citizenid VARCHAR(50))
BEGIN
    UPDATE doorlock_property_keys 
    SET 
        revoked = 1,
        revoked_by = revoked_by_citizenid,
        revoked_at = NOW()
    WHERE property_id = prop_id 
    AND revoked = 0;
    
    SELECT CONCAT('Toutes les clés de la propriété ', prop_id, ' ont été révoquées') as message;
END //
DELIMITER ;

-- ================================
-- TRIGGERS POUR L'AUDIT
-- ================================

-- Trigger pour logger les modifications de portes
DELIMITER //
CREATE TRIGGER IF NOT EXISTS `doorlock_audit_trigger`
    AFTER UPDATE ON doorlocks
    FOR EACH ROW
BEGIN
    IF OLD.locked != NEW.locked THEN
        INSERT INTO doorlock_security_logs (door_id, citizenid, event_type, details, severity)
        VALUES (NEW.id, COALESCE(NEW.last_user, 'SYSTEM'), 
                CASE WHEN NEW.locked = 1 THEN 'access_granted' ELSE 'access_granted' END,
                CONCAT('État changé: ', CASE WHEN NEW.locked = 1 THEN 'verrouillé' ELSE 'déverrouillé' END),
                'low');
    END IF;
END //
DELIMITER ;

-- ================================
-- OPTIMISATIONS ET PERFORMANCES
-- ================================

-- Optimiser les tables créées
ANALYZE TABLE doorlocks;
ANALYZE TABLE doorlock_logs;
ANALYZE TABLE doorlock_security_logs;
ANALYZE TABLE doorlock_maintenance;
ANALYZE TABLE doorlock_property_keys;

-- Index composites pour les requêtes fréquentes
ALTER TABLE doorlock_security_logs 
ADD INDEX IF NOT EXISTS `idx_door_time` (`door_id`, `timestamp`),
ADD INDEX IF NOT EXISTS `idx_citizen_time` (`citizenid`, `timestamp`),
ADD INDEX IF NOT EXISTS `idx_type_severity` (`event_type`, `severity`);

ALTER TABLE doorlock_property_keys
ADD INDEX IF NOT EXISTS `idx_property_type` (`property_id`, `key_type`),
ADD INDEX IF NOT EXISTS `idx_citizen_active` (`citizenid`, `revoked`, `expires_at`);

-- ================================
-- VÉRIFICATION DE L'INSTALLATION
-- ================================

-- Vérifier que toutes les tables ont été créées
SELECT 
    TABLE_NAME as 'Tables créées',
    TABLE_ROWS as 'Nombre de lignes',
    CREATE_TIME as 'Date de création'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME LIKE 'doorlock%'
ORDER BY TABLE_NAME;

-- Vérifier les portes par défaut
SELECT 
    COUNT(*) as 'Portes configurées',
    COUNT(CASE WHEN locked = 1 THEN 1 END) as 'Portes verrouillées',
    COUNT(CASE WHEN locked = 0 THEN 1 END) as 'Portes ouvertes'
FROM doorlocks;

-- Vérifier les index
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME LIKE 'doorlock%'
ORDER BY TABLE_NAME, INDEX_NAME;

-- ================================
-- MESSAGE FINAL
-- ================================

SELECT 
    '✅ Installation QB-Doorlock terminée avec succès!' as 'Statut',
    NOW() as 'Installé le',
    'Version 1.0.0 - Compatible PS-Housing v1.x et v2.0.x' as 'Version',
    'Consultez INSTALL.md pour la configuration des items' as 'Prochaine étape';

-- Afficher un résumé
SELECT 
    'Tables' as 'Composant',
    COUNT(*) as 'Quantité'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME LIKE 'doorlock%'

UNION ALL

SELECT 
    'Vues' as 'Composant',
    COUNT(*) as 'Quantité'
FROM information_schema.VIEWS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME LIKE 'doorlock%'

UNION ALL

SELECT 
    'Procédures' as 'Composant',
    COUNT(*) as 'Quantité'
FROM information_schema.ROUTINES 
WHERE ROUTINE_SCHEMA = DATABASE() 
AND ROUTINE_NAME LIKE '%doorlock%'
OR ROUTINE_NAME IN ('CleanupOldLogs', 'RevokeAllPropertyKeys');

-- Fin de l'installation
-- Vous pouvez maintenant configurer les items dans qb-core/shared/items.lua
-- ou utiliser le fichier sql/items.sql pour les ajouter automatiquement.
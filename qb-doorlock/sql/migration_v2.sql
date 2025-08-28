-- ================================
-- MIGRATION SQL v2.0 - QB-DOORLOCK
-- sql/migration_v2.sql
-- Scripts de migration base de données
-- ================================

-- ================================
-- MISE À JOUR STRUCTURE TABLES
-- ================================

-- Mise à jour table doorlocks pour v2.0
ALTER TABLE doorlocks 
ADD COLUMN IF NOT EXISTS property_type VARCHAR(50) DEFAULT 'standard' COMMENT 'Type de propriété (house, apartment, office, etc.)',
ADD COLUMN IF NOT EXISTS door_type VARCHAR(50) DEFAULT 'main' COMMENT 'Type de porte (main, garage, office, etc.)',
ADD COLUMN IF NOT EXISTS property_id VARCHAR(100) DEFAULT NULL COMMENT 'ID de la propriété (pour PS-Housing)',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Ajouter des index pour les performances
ALTER TABLE doorlocks 
ADD INDEX IF NOT EXISTS idx_property_type (property_type),
ADD INDEX IF NOT EXISTS idx_door_type (door_type),
ADD INDEX IF NOT EXISTS idx_property_id (property_id);

-- ================================
-- NOUVELLE TABLE SECURITY LOGS
-- ================================

CREATE TABLE IF NOT EXISTS doorlock_security_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    door_id VARCHAR(50) NOT NULL COMMENT 'ID de la porte',
    citizenid VARCHAR(50) NOT NULL COMMENT 'CitizenID du joueur',
    event_type ENUM(
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
    coordinates JSON DEFAULT NULL COMMENT 'Coordonnées de l\'événement',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Horodatage de l\'événement',
    details TEXT DEFAULT NULL COMMENT 'Détails supplémentaires',
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium' COMMENT 'Niveau de gravité',
    resolved BOOLEAN DEFAULT FALSE COMMENT 'Événement résolu',
    resolved_by VARCHAR(50) DEFAULT NULL COMMENT 'Résolu par (CitizenID)',
    resolved_at TIMESTAMP NULL DEFAULT NULL COMMENT 'Date de résolution',
    
    INDEX idx_door_id (door_id),
    INDEX idx_citizenid (citizenid),
    INDEX idx_event_type (event_type),
    INDEX idx_timestamp (timestamp),
    INDEX idx_severity (severity),
    INDEX idx_resolved (resolved)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Logs de sécurité avancés pour QB-Doorlock';

-- ================================
-- NOUVELLE TABLE MAINTENANCE
-- ================================

CREATE TABLE IF NOT EXISTS doorlock_maintenance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    door_id VARCHAR(50) NOT NULL COMMENT 'ID de la porte',
    maintenance_type ENUM(
        'scheduled', 
        'emergency', 
        'repair', 
        'inspection', 
        'upgrade'
    ) DEFAULT 'scheduled' COMMENT 'Type de maintenance',
    start_time TIMESTAMP NOT NULL COMMENT 'Heure de début prévue',
    end_time TIMESTAMP NOT NULL COMMENT 'Heure de fin prévue',
    actual_start TIMESTAMP NULL DEFAULT NULL COMMENT 'Heure de début réelle',
    actual_end TIMESTAMP NULL DEFAULT NULL COMMENT 'Heure de fin réelle',
    reason TEXT NOT NULL COMMENT 'Raison de la maintenance',
    description TEXT DEFAULT NULL COMMENT 'Description détaillée',
    scheduled_by VARCHAR(50) NOT NULL COMMENT 'Programmé par (CitizenID)',
    assigned_to VARCHAR(50) DEFAULT NULL COMMENT 'Assigné à (CitizenID)',
    status ENUM(
        'scheduled', 
        'in_progress', 
        'completed', 
        'cancelled', 
        'failed'
    ) DEFAULT 'scheduled' COMMENT 'Statut de la maintenance',
    completed BOOLEAN DEFAULT FALSE COMMENT 'Maintenance terminée',
    cost DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Coût de la maintenance',
    notes TEXT DEFAULT NULL COMMENT 'Notes supplémentaires',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_door_id (door_id),
    INDEX idx_maintenance_type (maintenance_type),
    INDEX idx_status (status),
    INDEX idx_scheduled_by (scheduled_by),
    INDEX idx_start_time (start_time),
    INDEX idx_completed (completed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Planning et historique de maintenance';

-- ================================
-- NOUVELLE TABLE PROPERTY KEYS
-- ================================

CREATE TABLE IF NOT EXISTS doorlock_property_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id VARCHAR(100) NOT NULL COMMENT 'ID de la propriété',
    citizenid VARCHAR(50) NOT NULL COMMENT 'CitizenID du détenteur de clé',
    key_type ENUM(
        'owner', 
        'tenant', 
        'manager', 
        'temporary', 
        'guest', 
        'service'
    ) NOT NULL COMMENT 'Type de clé/accès',
    permissions JSON DEFAULT NULL COMMENT 'Permissions spécifiques (portes accessibles)',
    expires_at TIMESTAMP NULL DEFAULT NULL COMMENT 'Date d\'expiration (pour clés temporaires)',
    granted_by VARCHAR(50) NOT NULL COMMENT 'Accordé par (CitizenID)',
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date d\'octroi',
    revoked BOOLEAN DEFAULT FALSE COMMENT 'Clé révoquée',
    revoked_by VARCHAR(50) DEFAULT NULL COMMENT 'Révoquée par (CitizenID)',
    revoked_at TIMESTAMP NULL DEFAULT NULL COMMENT 'Date de révocation',
    last_used TIMESTAMP NULL DEFAULT NULL COMMENT 'Dernière utilisation',
    use_count INT DEFAULT 0 COMMENT 'Nombre d\'utilisations',
    notes TEXT DEFAULT NULL COMMENT 'Notes supplémentaires',
    
    INDEX idx_property_id (property_id),
    INDEX idx_citizenid (citizenid),
    INDEX idx_key_type (key_type),
    INDEX idx_expires_at (expires_at),
    INDEX idx_granted_by (granted_by),
    INDEX idx_revoked (revoked),
    UNIQUE KEY unique_active_key (property_id, citizenid, key_type, revoked)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Gestion des clés de propriétés (PS-Housing v2.0)';

-- ================================
-- MIGRATION DES DONNÉES EXISTANTES
-- ================================

-- Migration des identifiants house_ vers property_
UPDATE doorlocks 
SET 
    id = REPLACE(id, 'house_', 'property_'),
    property_type = 'house',
    door_type = 'main',
    property_id = SUBSTRING(REPLACE(id, 'house_', ''), 1, LOCATE('_', REPLACE(id, 'house_', '')) - 1)
WHERE id LIKE 'house_%' AND property_type = 'standard';

-- Migration des logs existants
UPDATE doorlock_logs 
SET door_id = REPLACE(door_id, 'house_', 'property_')
WHERE door_id LIKE 'house_%';

-- Migration des données d'inventaire (clés)
UPDATE inventory 
SET name = REPLACE(name, 'house_key_', 'property_key_')
WHERE name LIKE 'house_key_%';

-- Mettre à jour les métadonnées des clés migrées
UPDATE inventory 
SET info = JSON_SET(
    COALESCE(info, '{}'),
    '$.migrated', true,
    '$.migration_date', NOW(),
    '$.type', 'owner'
)
WHERE name LIKE 'property_key_%' AND JSON_EXTRACT(info, '$.migrated') IS NULL;

-- ================================
-- DONNÉES DE TEST (DÉVELOPPEMENT)
-- ================================

-- Insérer des données de test pour le développement
-- ATTENTION: Commenter cette section en production !

/*
-- Données de test pour les logs de sécurité
INSERT INTO doorlock_security_logs (door_id, citizenid, event_type, details, severity) VALUES
('lspd_main_entrance', 'ABC123', 'access_granted', 'Accès normal avec badge police', 'low'),
('lspd_evidence', 'DEF456', 'access_denied', 'Tentative d\'accès sans autorisation', 'high'),
('property_test_main', 'GHI789', 'alarm', 'Tentative d\'effraction détectée', 'critical');

-- Données de test pour la maintenance
INSERT INTO doorlock_maintenance (door_id, maintenance_type, start_time, end_time, reason, scheduled_by, status) VALUES
('lspd_main_entrance', 'inspection', DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 1 DAY 2 HOUR), 'Inspection mensuelle programmée', 'SYSTEM', 'scheduled'),
('pillbox_surgery', 'repair', NOW(), DATE_ADD(NOW(), INTERVAL 3 HOUR), 'Réparation serrure défaillante', 'JKL012', 'in_progress');

-- Données de test pour les clés de propriétés
INSERT INTO doorlock_property_keys (property_id, citizenid, key_type, granted_by, permissions) VALUES
('test_house_001', 'ABC123', 'owner', 'SYSTEM', '{"main": true, "garage": true, "all": true}'),
('test_house_001', 'DEF456', 'tenant', 'ABC123', '{"main": true, "garage": false}'),
('office_downtown_01', 'GHI789', 'manager', 'JKL012', '{"main": true, "office": true, "conference": true}');
*/

-- ================================
-- VUES POUR FACILITER LES REQUÊTES
-- ================================

-- Vue pour les statistiques de sécurité
CREATE OR REPLACE VIEW doorlock_security_stats AS
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
CREATE OR REPLACE VIEW doorlock_active_maintenance AS
SELECT 
    m.*,
    d.property_type,
    d.property_id,
    TIMESTAMPDIFF(MINUTE, m.start_time, COALESCE(m.actual_end, NOW())) as duration_minutes
FROM doorlock_maintenance m
LEFT JOIN doorlocks d ON m.door_id = d.id
WHERE m.status IN ('scheduled', 'in_progress');

-- Vue pour les clés actives par propriété
CREATE OR REPLACE VIEW doorlock_active_keys AS
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
CREATE PROCEDURE IF NOT EXISTS CleanupOldLogs(IN days_to_keep INT)
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
CREATE PROCEDURE IF NOT EXISTS RevokeAllPropertyKeys(IN prop_id VARCHAR(100), IN revoked_by_citizenid VARCHAR(50))
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
CREATE TRIGGER IF NOT EXISTS doorlock_audit_trigger
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
-- OPTIMISATIONS ET INDEX
-- ================================

-- Optimiser les requêtes fréquentes
ANALYZE TABLE doorlocks;
ANALYZE TABLE doorlock_logs;
ANALYZE TABLE doorlock_security_logs;
ANALYZE TABLE doorlock_maintenance;
ANALYZE TABLE doorlock_property_keys;

-- Index composites pour les requêtes complexes
ALTER TABLE doorlock_security_logs 
ADD INDEX IF NOT EXISTS idx_door_time (door_id, timestamp),
ADD INDEX IF NOT EXISTS idx_citizen_time (citizenid, timestamp),
ADD INDEX IF NOT EXISTS idx_type_severity (event_type, severity);

ALTER TABLE doorlock_property_keys
ADD INDEX IF NOT EXISTS idx_property_type (property_id, key_type),
ADD INDEX IF NOT EXISTS idx_citizen_active (citizenid, revoked, expires_at);

-- ================================
-- INFORMATIONS DE MIGRATION
-- ================================

-- Table pour tracker les migrations
CREATE TABLE IF NOT EXISTS doorlock_migrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(20) NOT NULL,
    description TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms INT DEFAULT 0,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT DEFAULT NULL,
    
    UNIQUE KEY unique_version (version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historique des migrations QB-Doorlock';

-- Enregistrer cette migration
INSERT INTO doorlock_migrations (version, description, execution_time_ms) 
VALUES ('2.0.0', 'Migration complète vers v2.0 avec PS-Housing v2.0.x, sécurité avancée et maintenance', 0)
ON DUPLICATE KEY UPDATE 
    executed_at = CURRENT_TIMESTAMP,
    description = VALUES(description);

-- ================================
-- VÉRIFICATIONS FINALES
-- ================================

-- Vérifier l'intégrité des données migrées
SELECT 
    'doorlocks' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN property_type != 'standard' THEN 1 END) as migrated_records
FROM doorlocks
UNION ALL
SELECT 
    'doorlock_security_logs' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN event_type IN ('alarm', 'breach') THEN 1 END) as security_events
FROM doorlock_security_logs
UNION ALL
SELECT 
    'doorlock_maintenance' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN status = 'scheduled' THEN 1 END) as scheduled_maintenance
FROM doorlock_maintenance;

-- Message de fin
SELECT 
    '✅ Migration v2.0 terminée avec succès!' as status,
    NOW() as completed_at,
    'QB-Doorlock est maintenant compatible PS-Housing v2.0.x' as message;
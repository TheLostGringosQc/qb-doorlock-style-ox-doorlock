-- ================================
-- ITEMS SQL - QB-DOORLOCK
-- sql/items.sql
-- Items à ajouter automatiquement en base
-- ================================

-- ================================
-- ITEMS POUR QB-CORE
-- Ces items peuvent être ajoutés directement en base
-- ou dans qb-core/shared/items.lua
-- ================================

-- Items de base pour les systèmes de sécurité
INSERT INTO `items` (`name`, `label`, `weight`, `type`, `image`, `unique`, `useable`, `shouldClose`, `combinable`, `description`) VALUES

-- ================================
-- ITEMS POUR JOBS DE SÉCURITÉ
-- ================================

-- Police
('police_keycard', 'carte daccès PD', 100, 'item', 'police_keycard.png', 0, 1, 0, NULL, 'Badge daccès pour le commissariat LSPD'),
('police_keys', 'Clés des Cellules', 200, 'item', 'police_keys.png', 0, 1, 0, NULL, 'Trousseau de clés pour les cellules de police'),
('evidence_keycard', 'carte daccès salle des preuves', 100, 'item', 'evidence_keycard.png', 0, 1, 0, NULL, 'Accès à la salle des preuves - Grade élevé requis'),

-- Ambulance/Hôpital
('hospital_keycard', 'carte daccès hopital', 100, 'item', 'hospital_keycard.png', 0, 1, 0, NULL, 'Badge daccès pour lhôpital Pillbox'),
('surgery_keycard', 'Accès Bloc Opératoire', 100, 'item', 'surgery_keycard.png', 0, 1, 0, NULL, 'Accès au bloc opératoire - Personnel médical'),

-- Mécanicien
('garage_keys', 'Clés du Garage', 300, 'item', 'garage_keys.png', 0, 1, 0, NULL, 'Trousseau de clés pour garage mécanique'),

-- ================================
-- ITEMS POUR BANQUES ET SÉCURITÉ
-- ================================

('bank_card', 'Carte Bancaire Sécurisée', 50, 'item', 'bank_card.png', 1, 1, 1, NULL, 'Carte daccès au coffre-fort - Usage unique'),
('security_code', 'Code de Sécurité', 10, 'item', 'security_code.png', 1, 1, 1, NULL, 'Code daccès temporaire pour systèmes sécurisés'),

-- ================================
-- ITEMS PS-HOUSING (MAISONS/PROPRIÉTÉS)
-- ================================

-- Clés de maison (template pour génération dynamique)
('house_key_template', 'Clé de Maison', 50, 'item', 'house_key.png', 1, 1, 0, NULL, 'Clé dune maison privée'),
('property_key_template', 'Clé de Propriété', 50, 'item', 'property_key.png', 1, 1, 0, NULL, 'Clé dune propriété (maison, appartement, bureau)'),

-- Clés spécialisées PS-Housing v2.0
('tenant_key_template', 'Clé de Locataire', 50, 'item', 'tenant_key.png', 1, 1, 0, NULL, 'Clé de locataire avec accès limité'),
('manager_key_template', 'Clé de Gestionnaire', 75, 'item', 'manager_key.png', 1, 1, 0, NULL, 'Clé de gestionnaire de propriété'),

-- ================================
-- OUTILS DE DUPLICATION ET MAINTENANCE
-- ================================

('key_duplication_kit', 'Kit de Duplication', 500, 'item', 'key_duplication_kit.png', 0, 1, 1, NULL, 'Permet de dupliquer des clés de maison'),
('lockpick_advanced', 'Kit de Crochetage Avancé', 200, 'item', 'lockpick_advanced.png', 0, 1, 1, NULL, 'Outils professionnels pour systèmes complexes'),
('electronic_lockpick', 'Crochetage Électronique', 150, 'item', 'electronic_lockpick.png', 0, 1, 1, NULL, 'Appareil pour contourner les serrures électroniques'),

-- ================================
-- ITEMS POUR AGENTS IMMOBILIERS
-- ================================

('master_key', 'Passe-Partout', 100, 'item', 'master_key.png', 1, 1, 0, NULL, 'Clé universelle pour agent immobilier'),
('realtor_keycard', 'carte daccès agent Immobilier', 75, 'item', 'realtor_keycard.png', 0, 1, 0, NULL, 'carte daccès dagent immobilier pour accès propriétés'),

-- ================================
-- CARTES D'ACCÈS TEMPORAIRES
-- ================================

('temp_access_card', 'Carte dAccès Temporaire', 25, 'item', 'temp_access_card.png', 1, 1, 1, NULL, 'Carte daccès temporaire - durée limitée'),
('guest_pass', 'Pass Invité', 10, 'item', 'guest_pass.png', 1, 1, 1, NULL, 'Pass temporaire pour invités'),

-- ================================
-- ITEMS DE MAINTENANCE
-- ================================

('door_repair_kit', 'Kit de Réparation', 800, 'item', 'door_repair_kit.png', 0, 1, 1, NULL, 'Kit complet pour réparation de portes'),
('lock_oil', 'Huile pour Serrures', 100, 'item', 'lock_oil.png', 0, 1, 1, NULL, 'Lubrifiant pour mécanismes de verrouillage'),
('door_sensor', 'Capteur de Porte', 200, 'item', 'door_sensor.png', 0, 1, 0, NULL, 'Capteur pour système dalarme de porte'),

-- ================================
-- ITEMS SPÉCIAUX POUR BRAQUAGES
-- ================================

('thermite_door', 'Thermite Spéciale', 300, 'item', 'thermite_door.png', 1, 1, 1, NULL, 'Explosif pour faire sauter les portes blindées'),
('hacking_device', 'Dispositif de Piratage', 250, 'item', 'hacking_device.png', 1, 1, 1, NULL, 'Appareil pour pirater les systèmes électroniques'),
('emp_device', 'Générateur EMP', 400, 'item', 'emp_device.png', 1, 1, 1, NULL, 'Désactive temporairement les systèmes électroniques'),

-- ================================
-- CONSOMMABLES POUR SYSTÈMES AVANCÉS
-- ================================

('keycard_blank', 'Carte Vierge', 50, 'item', 'keycard_blank.png', 0, 1, 1, NULL, 'Carte magnétique vierge pour programmation'),
('access_programmer', 'Programmateur dAccès', 1000, 'item', 'access_programmer.png', 0, 1, 0, NULL, 'Appareil pour programmer les cartes daccès'),

-- ================================
-- ITEMS DE SURVEILLANCE
-- ================================

('security_camera_kit', 'Kit Caméra de Surveillance', 600, 'item', 'security_camera.png', 0, 1, 1, NULL, 'Kit dinstallation de caméra de sécurité'),
('motion_detector', 'Détecteur de Mouvement', 300, 'item', 'motion_detector.png', 0, 1, 1, NULL, 'Détecteur pour système dalarme'),
('alarm_panel', 'Panneau dAlarme', 800, 'item', 'alarm_panel.png', 0, 1, 1, NULL, 'Panneau de contrôle pour système dalarme')

ON DUPLICATE KEY UPDATE 
    `label` = VALUES(`label`),
    `description` = VALUES(`description`);

-- ================================
-- RECETTES DE CRAFT (OPTIONNEL)
-- ================================

-- Recettes pour les items craftables
INSERT INTO `crafting_recipes` (`item`, `ingredients`, `amount`, `job`, `skill_required`) VALUES

-- Kit de duplication (mécanicien)
('key_duplication_kit', JSON_OBJECT(
    'metalscrap', 5,
    'plastic', 3,
    'electronics', 2
), 1, 'mechanic', 25),

-- Kit de réparation de porte (mécanicien)
('door_repair_kit', JSON_OBJECT(
    'metalscrap', 10,
    'screws', 15,
    'plastic', 5,
    'electronics', 1
), 1, 'mechanic', 40),

-- Dispositif de piratage (job illégal)
('hacking_device', JSON_OBJECT(
    'electronics', 5,
    'metalscrap', 3,
    'plastic', 2,
    'copper', 10
), 1, NULL, 60),

-- Carte d'accès programmée
('temp_access_card', JSON_OBJECT(
    'keycard_blank', 1,
    'electronics', 1
), 1, 'realestate', 10)

ON DUPLICATE KEY UPDATE 
    `ingredients` = VALUES(`ingredients`),
    `amount` = VALUES(`amount`);

-- ================================
-- CONFIGURATION DES VENDEURS
-- ================================

-- Items vendus par les vendeurs légaux
INSERT INTO `shop_items` (`shop`, `item`, `price`, `stock`) VALUES

-- Vendeur d'outils (légal)
('hardware_store', 'lock_oil', 25, 50),
('hardware_store', 'keycard_blank', 15, 100),
('hardware_store', 'door_sensor', 85, 20),

-- Vendeur électronique
('electronics_store', 'access_programmer', 10000, 5),
('electronics_store', 'electronic_lockpick', 20000, 10),

-- Marché noir (illégal)
('blackmarket', 'hacking_device', 800, 3),
('blackmarket', 'emp_device', 1200, 2),
('blackmarket', 'thermite_door', 500, 5),
('blackmarket', 'lockpick_advanced', 300, 8)

ON DUPLICATE KEY UPDATE 
    `price` = VALUES(`price`),
    `stock` = VALUES(`stock`);

-- ================================
-- DROPS ET RÉCOMPENSES
-- ================================

-- Items que peuvent drop les NPCs
INSERT INTO `npc_drops` (`npc_type`, `item`, `chance`, `min_amount`, `max_amount`) VALUES

-- Security guards peuvent drop des cartes
('security_guard', 'security_code', 15, 1, 1),
('security_guard', 'temp_access_card', 10, 1, 2),

-- Police peut drop des badges
('police_officer', 'police_keycard', 5, 1, 1),

-- Techniciens peuvent drop des outils
('technician', 'door_repair_kit', 20, 1, 1),
('technician', 'lock_oil', 35, 1, 3)

ON DUPLICATE KEY UPDATE 
    `chance` = VALUES(`chance`);

-- ================================
-- COMPATIBILITÉ AVEC D'AUTRES SYSTÈMES
-- ================================

-- Ajout des métadonnées par défaut pour certains items
UPDATE `items` 
SET `description` = CONCAT(`description`, ' [Compatible QB-Doorlock]')
WHERE `name` IN ('lockpick', 'advancedlockpick') 
AND `description` NOT LIKE '%Compatible QB-Doorlock%';

-- ================================
-- INFORMATIONS ET STATISTIQUES
-- ================================

-- Voir combien d'items ont été ajoutés
SELECT 
    'Items QB-Doorlock ajoutés' as category,
    COUNT(*) as count
FROM `items` 
WHERE `description` LIKE '%QB-Doorlock%' 
   OR `name` LIKE '%key%' 
   OR `name` LIKE '%card%' 
   OR `name` LIKE '%lock%';

-- Résumé par catégorie
SELECT 
    CASE 
        WHEN `name` LIKE '%police%' THEN 'Police'
        WHEN `name` LIKE '%hospital%' OR `name` LIKE '%surgery%' THEN 'Médical'
        WHEN `name` LIKE '%bank%' OR `name` LIKE '%security%' THEN 'Sécurité'
        WHEN `name` LIKE '%house%' OR `name` LIKE '%property%' THEN 'Immobilier'
        WHEN `name` LIKE '%key%' THEN 'Clés'
        WHEN `name` LIKE '%repair%' OR `name` LIKE '%maintenance%' THEN 'Maintenance'
        ELSE 'Autre'
    END as category,
    COUNT(*) as item_count
FROM `items` 
WHERE `name` IN (
    'police_keycard', 'police_keys', 'evidence_keycard',
    'hospital_keycard', 'surgery_keycard', 'garage_keys',
    'bank_card', 'security_code', 'house_key_template',
    'property_key_template', 'key_duplication_kit', 'master_key',
    'temp_access_card', 'door_repair_kit', 'lock_oil',
    'hacking_device', 'thermite_door', 'emp_device'
)
GROUP BY category;

-- Message de confirmation
SELECT 
    '✅ Items QB-Doorlock installés avec succès!' as status,
    'Vérifiez qb-core/shared/items.lua ou utilisez ces items depuis la base' as message,
    NOW() as installed_at;
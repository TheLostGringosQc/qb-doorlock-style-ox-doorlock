-- ================================
-- ITEMS POUR ps-inventory
-- ================================

-- Ajouter ces items dans qb-core/shared/items.lua

-- ================================
-- ITEMS POUR JOBS DE SÉCURITÉ
-- ================================

-- Police
['police_keycard'] = {
    ['name'] = 'police_keycard',
    ['label'] = 'carte d\'accès PD',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'police_keycard.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'carte d\'accès pour le commissariat'
},

['police_keys'] = {
    ['name'] = 'police_keys',
    ['label'] = 'Clés des Cellules',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'police_keys.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Trousseau de clés pour les cellules'
},

['evidence_keycard'] = {
    ['name'] = 'evidence_keycard',
    ['label'] = 'carte d\'accès salle des Preuves',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'evidence_keycard.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Accès à la salle des preuves - Grade requis'
},

-- Ambulance/Hôpital
['hospital_keycard'] = {
    ['name'] = 'hospital_keycard',
    ['label'] = 'carte daccès hopital',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'hospital_keycard.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'clé d\'accès hospitalier'
},

['surgery_keycard'] = {
    ['name'] = 'surgery_keycard',
    ['label'] = 'Accès Bloc Opératoire',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'surgery_keycard.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Accès au bloc opératoire'
},

-- Mécanicien
['garage_keys'] = {
    ['name'] = 'garage_keys',
    ['label'] = 'Clés du Garage',
    ['weight'] = 300,
    ['type'] = 'item',
    ['image'] = 'garage_keys.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Trousseau de clés du garage mécanique'
},

-- ================================
-- ITEMS POUR BANQUES ET SÉCURITÉ
-- ================================

['bank_card'] = {
    ['name'] = 'bank_card',
    ['label'] = 'Carte Bancaire Sécurisée',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'bank_card.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Carte d\'accès au coffre-fort - Usage unique'
},

['security_code'] = {
    ['name'] = 'security_code',
    ['label'] = 'Code de Sécurité',
    ['weight'] = 10,
    ['type'] = 'item',
    ['image'] = 'security_code.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Code d\'accès temporaire'
},

-- ================================
-- ITEMS PS-HOUSING (MAISONS/PROPRIÉTÉS)
-- ================================

-- Clés de maison (template pour génération dynamique)
['house_key_template'] = {
    ['name'] = 'house_key_template',
    ['label'] = 'Clé de Maison',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'house_key.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Clé pour une maison privée'
},

['property_key_template'] = {
    ['name'] = 'property_key_template',
    ['label'] = 'Clé de Propriété',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'property_key.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Clé dune propriété (maison, appartement, bureau)'
},

-- Clés spécialisées PS-Housing v2.0
['tenant_key_template'] = {
    ['name'] = 'tenant_key_template',
    ['label'] = 'Clé de Locataire',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'tenant_key.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Clé de locataire avec accès limité'
},

['manager_key_template'] = {
    ['name'] = 'manager_key_template',
    ['label'] = 'Clé de Gestionnaire',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'manager_key.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Clé de gestionnaire de propriété'
},

-- ================================
-- OUTILS DE DUPLICATION ET MAINTENANCE
-- ================================

['key_duplication_kit'] = {
    ['name'] = 'key_duplication_kit',
    ['label'] = 'Kit de Duplication',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'key_duplication_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Permet de dupliquer des clés de maison'
},

['lockpick_advanced'] = {
    ['name'] = 'lockpick_advanced',
    ['label'] = 'Kit de Crochetage Avancé',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'lockpick_advanced.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Outils professionnels pour systèmes complexes'
},

['electronic_lockpick'] = {
    ['name'] = 'electronic_lockpick',
    ['label'] = 'Crochetage Électronique',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'electronic_lockpick.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Appareil pour contourner les serrures électroniques'
},

-- ================================
-- ITEMS POUR AGENTS IMMOBILIERS
-- ================================

['master_key'] = {
    ['name'] = 'master_key',
    ['label'] = 'Passe-Partout',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'master_key.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Clé universelle pour agent immobilier'
},

['realtor_keycard'] = {
    ['name'] = 'realtor_keycard',
    ['label'] = 'carte daccès agent Immobilier',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'realtor_keycard.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'carte daccès dagent immobilier pour accès propriétés'
},

-- ================================
-- CARTES D'ACCÈS TEMPORAIRES
-- ================================

['temp_access_card'] = {
    ['name'] = 'temp_access_card',
    ['label'] = 'Carte dAccès Temporaire',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'temp_access_card.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Carte daccès temporaire - durée limitée'
},

['guest_pass'] = {
    ['name'] = 'guest_pass',
    ['label'] = 'Pass Invité',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'guest_pass.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Pass temporaire pour invités'
},

-- ================================
-- ITEMS DE MAINTENANCE
-- ================================

['door_repair_kit'] = {
    ['name'] = 'door_repair_kit',
    ['label'] = 'Kit de Réparation',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'door_repair_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Kit complet pour réparation de portes'
},

['lock_oil'] = {
    ['name'] = 'lock_oil',
    ['label'] = 'Huile pour Serrures',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'lock_oil.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Lubrifiant pour mécanismes de verrouillage'
},

['door_sensor'] = {
    ['name'] = 'door_sensor',
    ['label'] = 'Capteur de Porte',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'door_sensor.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Capteur pour système dalarme de porte'
},

-- ================================
-- ITEMS SPÉCIAUX POUR BRAQUAGES
-- ================================

['thermite_door'] = {
    ['name'] = 'thermite_door',
    ['label'] = 'Thermite Spéciale',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'thermite_door.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Explosif pour faire sauter les portes blindées'
},

['hacking_device'] = {
    ['name'] = 'hacking_device',
    ['label'] = 'Dispositif de Piratage',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'hacking_device.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Appareil pour pirater les systèmes électroniques'
},

['emp_device'] = {
    ['name'] = 'emp_device',
    ['label'] = 'Générateur EMP',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'emp_device.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Désactive temporairement les systèmes électroniques'
},

-- ================================
-- CONSOMMABLES POUR SYSTÈMES AVANCÉS
-- ================================

['keycard_blank'] = {
    ['name'] = 'keycard_blank',
    ['label'] = 'Carte Vierge',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'keycard_blank.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Carte magnétique vierge pour programmation'
},

['access_programmer'] = {
    ['name'] = 'Programmateur dAccès',
    ['label'] = 'access_programmer',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'access_programmer.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'Appareil pour programmer les cartes daccès'
},

-- ================================
-- ITEMS DE SURVEILLANCE
-- ================================

['security_camera_kit'] = {
    ['name'] = 'security_camera_kit',
    ['label'] = 'Kit Caméra de Surveillance',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'security_camera_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Kit dinstallation de caméra de sécurité'
},

['motion_detector'] = {
    ['name'] = 'smotion_detector',
    ['label'] = 'Détecteur de Mouvement',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'motion_detector.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Détecteur pour système dalarme'
},

['alarm_panel'] = {
    ['name'] = 'alarm_panel',
    ['label'] = 'Panneau dAlarme',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'alarm_panel.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Panneau de contrôle pour système dalarme'
},

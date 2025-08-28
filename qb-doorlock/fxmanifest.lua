-- ================================
-- FXMANIFEST.LUA FINAL - QB-DOORLOCK
-- Version complète avec intégration PS-Housing v1.x et v2.0.x
-- ================================

fx_version 'cerulean'
game 'gta5'

-- Informations de la ressource
name 'QB-Doorlock'
description 'Système de verrouillage avancé inspiré d\'ox-doorlock pour QBCore avec intégration PS-Housing'
author 'LaPetiteVieDEV'
version '1.2.0'

-- Scripts partagés (chargés côté client ET serveur)
shared_scripts {
    'config.lua'
}

-- Scripts client
client_scripts {
    -- Core client
    'client/main.lua',
    
    -- Intégrations PS-Housing
    'client/pshousing_integration.lua',     -- v1.x (rétrocompatibilité)
    'client/pshousing_v2_integration.lua', -- v2.0.x (nouveau)
    
    -- Fonctionnalités avancées
    'client/ui_manager.lua',               -- Gestion interface utilisateur
}

-- Scripts serveur
server_scripts {
    -- Database
    '@oxmysql/lib/MySQL.lua',
    
    -- Core server
    'server/main.lua',
    
    -- Intégrations PS-Housing
    'server/pshousing_integration.lua',     -- v1.x (rétrocompatibilité)
    'server/pshousing_v2_integration.lua', -- v2.0.x (nouveau)
    
    -- Systèmes avancés
    'server/advanced_systems.lua',         -- Systèmes avancés
    'server/migration.lua',                 -- Migration v1.x vers v2.0.x
    
    -- Tests (développement uniquement)
    -- 'tests/pshousing_v2_compatibility.lua', -- Décommenter pour tests
}

-- Interface NUI
ui_page 'html/index.html'

files {
    -- Interface utilisateur
    'html/index.html',
    'html/style.css',
    'html/script.js',
    
    -- Assets (images, sons, etc.)
    'html/assets/*.png',
    'html/assets/*.jpg',
    'html/assets/*.svg',
    'html/assets/*.mp3',
    'html/assets/*.wav',
}

-- Dépendances requises
dependencies {
    -- Framework principal
    'qb-core',
    
    -- Systèmes d'interaction
    'qb-target',
    
    -- Inventaire
    'ps-inventory',
    
    -- Base de données
    'oxmysql',
}

-- Dépendances optionnelles (intégrations)
optional_dependencies {
    -- Système de logement (une des deux versions)
    'ps-housing',           -- v1.x ou v2.0.x
    
    -- Autres intégrations optionnelles
    'qb-gangs',            -- Support des gangs
    'qb-weathersync',      -- Intégration météo
    'qb-apartments',       -- Appartements QBCore
    'qb-phone',            -- Notifications téléphone
    'qb-logs',             -- Système de logs avancé
}

-- Variables d'environnement et configuration
data_file 'DLC_ITYP_REQUEST' 'stream/**/*.ytyp'

-- Permissions et sécurité
server_export 'GetDoorState'
server_export 'SetDoorState'
server_export 'editDoorlock'              -- Compatibilité ox_doorlock
server_export 'createHouseDoor'           -- PS-Housing v1.x
server_export 'createPropertyDoor'        -- PS-Housing v2.0.x
server_export 'hasHouseAccess'            -- PS-Housing v1.x
server_export 'hasPropertyAccess'         -- PS-Housing v2.0.x
server_export 'getPropertyDoors'          -- PS-Housing v2.0.x
server_export 'runPSHousingV2Tests'       -- Tests de compatibilité

client_export 'ToggleLock'
client_export 'IsAuthorized'
client_export 'GetDoorState'
client_export 'GetNearbyDoors'
client_export 'ToggleDoorGroup'
client_export 'getHouseDoorState'         -- PS-Housing v1.x
client_export 'hasHouseDoor'              -- PS-Housing v1.x
client_export 'getNearbyHouses'           -- PS-Housing v1.x
client_export 'getNearbyProperties'       -- PS-Housing v2.0.x

-- Événements réseau autorisés
-- (Sécurité : liste blanche des events que les clients peuvent déclencher)
server_events {
    'qb-doorlock:server:updateState',
    'qb-doorlock:server:toggleLock',
    'qb-doorlock:server:toggleGroup',
    'qb-doorlock:server:checkCode',
    'qb-doorlock:server:multiKeyAccess',
    'qb-doorlock:server:emergencyAccess',
    
    -- PS-Housing v1.x
    'qb-doorlock:server:houseInteraction',
    'qb-doorlock:server:createHouseDoorAtPosition',
    'qb-doorlock:server:duplicateKey',
    'qb-doorlock:server:reportIssue',
    
    -- PS-Housing v2.0.x
    'qb-doorlock:server:propertyInteraction',
    'qb-doorlock:server:createPropertyDoorAtPosition',
    'qb-doorlock:server:addTenant',
    'qb-doorlock:server:removeTenant',
    'qb-doorlock:server:addManager',
    'qb-doorlock:server:removeManager',
}

client_events {
    'qb-doorlock:client:setState',
    'qb-doorlock:client:toggleLock',
    'qb-doorlock:client:requestCode',
    'qb-doorlock:client:codeResult',
    'qb-doorlock:client:alarmAlert',
    'qb-doorlock:client:reloadConfig',
    'qb-doorlock:client:multiKeyAccess',
    'qb-doorlock:client:emergencyMode',
    
    -- PS-Housing v1.x
    'qb-doorlock:client:houseInteraction',
    'qb-doorlock:client:addHouseDoor',
    'qb-doorlock:client:removeHouseDoor',
    'qb-doorlock:client:houseStateChanged',
    'qb-doorlock:client:duplicateKey',
    
    -- PS-Housing v2.0.x
    'qb-doorlock:client:propertyInteraction',
    'qb-doorlock:client:addPropertyDoor',
    'qb-doorlock:client:removePropertyDoor',
    'qb-doorlock:client:propertyStateChanged',
    'qb-doorlock:client:tenantAdded',
    'qb-doorlock:client:tenantRemoved',
    'qb-doorlock:client:managerAdded',
}

-- Configuration Lua environnement
lua54 'yes'

-- Optimisations de performance
escrow_ignore {
    'config.lua',
    'server/utils.lua',
    'client/advanced_features.lua',
    'tests/*.lua',
    'README.md',
    'INSTALL.md',
    'CHANGELOG.md'
}

-- Métadonnées pour FXServer
metadata {
    -- Compatibilité
    ['fxdk_watch_command'] = 'restart qb-doorlock',
    ['fxdk_start_command'] = 'start qb-doorlock',
    
    -- Categories pour les menus d'administration
    ['category'] = 'qbcore,doors,security,housing',
    ['tags'] = 'qbcore,doorlock,ps-housing,security,doors,locks',
    
    -- Support et documentation
    ['support_url'] = 'https://discord.gg/qbcore',
    ['documentation_url'] = 'https://docs.qbcore.org/qb-doorlock',
    
    -- Compatibility
    ['qbcore_compatible'] = 'yes',
    ['ps_housing_v1_compatible'] = 'yes',
    ['ps_housing_v2_compatible'] = 'yes',
    ['ox_doorlock_compatible'] = 'partial',
}

-- Vérifications au démarrage
-- (Ces vérifications s'exécutent au chargement de la ressource)
if not GetResourceState then
    print('^1[QB-DOORLOCK] ERREUR: Cette ressource nécessite FXServer b2699 ou supérieur^7')
    return
end

-- Vérifier QBCore
if GetResourceState('qb-core') ~= 'started' then
    print('^3[QB-DOORLOCK] ATTENTION: qb-core n\'est pas démarré. Cette ressource ne fonctionnera pas correctement.^7')
end

-- Vérifier qb-target
if GetResourceState('qb-target') ~= 'started' then
    print('^3[QB-DOORLOCK] ATTENTION: qb-target n\'est pas démarré. Les interactions target ne fonctionneront pas.^7')
end

-- Vérifier ps-inventory
if GetResourceState('ps-inventory') ~= 'started' then
    print('^3[QB-DOORLOCK] ATTENTION: ps-inventory n\'est pas démarré. La vérification des items ne fonctionnera pas.^7')
end

-- Vérifier ps-housing (optionnel)
local psHousingState = GetResourceState('ps-housing')
if psHousingState == 'started' then
    print('^2[QB-DOORLOCK] PS-Housing détecté et démarré. Intégration activée.^7')
elseif psHousingState == 'starting' then
    print('^3[QB-DOORLOCK] PS-Housing en cours de démarrage. Attente de l\'intégration...^7')
else
    print('^6[QB-DOORLOCK] PS-Housing non détecté. Fonctionnement en mode standard.^7')
end

-- Vérifier oxmysql
if GetResourceState('oxmysql') ~= 'started' then
    print('^1[QB-DOORLOCK] ERREUR: oxmysql n\'est pas démarré. La base de données ne fonctionnera pas.^7')
end

-- Messages d'information au démarrage
print('^2[QB-DOORLOCK] Ressource QB-Doorlock chargée - Version 1.2.0^7')
print('^6[QB-DOORLOCK] Intégration PS-Housing v1.x et v2.0.x disponible^7')
print('^6[QB-DOORLOCK] Inspiré d\'ox-doorlock avec compatibilité partielle^7')

-- ================================
-- STRUCTURE DES FICHIERS
-- ================================

--[[
Structure recommandée du dossier qb-doorlock :

qb-doorlock/
├── fxmanifest.lua                          # Ce fichier
├── config.lua                              # Configuration principale
├── README.md                               # Documentation
├── INSTALL.md                              # Guide d'installation
├── CHANGELOG.md                            # Historique des versions
├──
├── client/
│   ├── main.lua                           # Script client principal
│   ├── pshousing_integration.lua          # Intégration PS-Housing v1.x
│   ├── pshousing_v2_integration.lua       # Intégration PS-Housing v2.0.x
│   ├── advanced_features.lua              # Fonctionnalités avancées
│   └── ui_manager.lua                     # Gestion interface utilisateur
├──
├── server/
│   ├── main.lua                           # Script serveur principal
│   ├── pshousing_integration.lua          # Intégration PS-Housing v1.x serveur
│   ├── pshousing_v2_integration.lua       # Intégration PS-Housing v2.0.x serveur
│   ├── utils.lua                          # Fonctions utilitaires serveur
│   ├── advanced_systems.lua              # Systèmes avancés (alarmes, etc.)
│   └── migration.lua                      # Migration v1.x vers v2.0.x
├──
├── html/
│   ├── index.html                         # Interface NUI principale
│   ├── style.css                          # Styles CSS
│   ├── script.js                          # JavaScript NUI
│   └── assets/                            # Images, sons, etc.
│       ├── door_icon.png
│       ├── lock_sound.mp3
│       └── unlock_sound.mp3
├──
├── sql/
│   ├── install.sql                        # Installation base de données
│   ├── migration_v2.sql                   # Migration vers v2.0
│   └── items.sql                          # Items pour ps-inventory
├──
├── tests/ (optionnel - développement)
│   ├── pshousing_v2_compatibility.lua     # Tests de compatibilité v2.0
│   ├── performance_tests.lua              # Tests de performance
│   └── integration_tests.lua              # Tests d'intégration
└──
└── docs/ (optionnel)
    ├── API.md                             # Documentation API
    ├── PSHOUSING_INTEGRATION.md           # Guide intégration PS-Housing
    └── TROUBLESHOOTING.md                 # Résolution de problèmes
--]]

-- ================================
-- NOTES D'INSTALLATION
-- ================================

--[[
INSTALLATION RAPIDE :

1. Copier le dossier dans [qb]/qb-doorlock/
2. Ajouter dans server.cfg : ensure qb-doorlock
3. Importer le SQL : source sql/install.sql
4. Ajouter les items dans qb-core/shared/items.lua
5. Redémarrer le serveur

ORDRE DE DÉMARRAGE RECOMMANDÉ :
1. oxmysql
2. qb-core
3. ps-inventory
4. qb-target
5. ps-housing (si utilisé)
6. qb-doorlock

INTÉGRATION PS-HOUSING :
- v1.x : Automatique si ps-housing détecté
- v2.0.x : Détection automatique avec tests de compatibilité
- Les deux versions peuvent coexister (rétrocompatibilité)

MIGRATION v1.x → v2.0.x :
1. /testpshousingv2 (vérifier compatibilité)
2. Sauvegarder la base de données
3. Exécuter sql/migration_v2.sql
4. Redémarrer qb-doorlock
5. Vérifier avec /pshousinginfo
--]]

-- ================================
-- COMMANDES DISPONIBLES
-- ================================

--[[
COMMANDES ADMIN :
/adoorlock [doorId] [true/false]     - Forcer l'état d'une porte
/doorlogs [doorId]                   - Voir les logs d'une porte  
/reloaddoors                         - Recharger la configuration
/cleandoorlogs [days]                - Nettoyer les anciens logs
/emergencyunlock [job]               - Déverrouiller toutes les portes d'un job
/testpshousingv2                     - Tester compatibilité PS-Housing v2.0
/pshousinginfo                       - Informations intégration PS-Housing

COMMANDES MAISONS (PS-Housing v1.x) :
/createhousedoor [houseId] [model]   - Créer une porte de maison
/givehousekey [playerId] [houseId]   - Donner une clé de maison
/nearbyhouses                        - Lister les maisons proches

COMMANDES PROPRIÉTÉS (PS-Housing v2.0.x) :
/createpropertydoor [propId] [type]  - Créer une porte de propriété
/addtenant [propId] [playerId]       - Ajouter un locataire
/addmanager [propId] [playerId]      - Ajouter un gestionnaire
/repairpropertydoor [propId] [type]  - Réparer une porte

COMMANDES JOUEUR :
/doorlock [doorId]                   - Toggle une porte (debug)
/duplicatekey                        - Dupliquer une clé (avec kit)
--]]

-- ================================
-- SUPPORT ET COMMUNAUTÉ
-- ================================

--[[
SUPPORT :
- Discord QBCore : https://discord.gg/qbcore
- Documentation : https://docs.qbcore.org/qb-doorlock
- Issues GitHub : https://github.com/qbcore/qb-doorlock/issues

CONTRIBUTIONS :
- Pull Requests welcome sur GitHub
- Tests de compatibilité appréciés
- Rapports de bugs détaillés
- Suggestions d'améliorations

CRÉDITS :
- Inspiré d'ox-doorlock par Overextended
- Compatible PS-Housing par Project Sloth
- Développé pour la communauté QBCore
- Contributeurs : [Voir GitHub]

LICENCE :
- Open Source sous licence GPL-3.0
- Libre d'utilisation et modification
- Attribution requise
- Pas de garantie commercial
--]]

-- ================================
-- OPTIMISATIONS DE PERFORMANCE
-- ================================

-- Optimisations pour serveurs haute population
performance {
    -- Limitation du nombre de portes actives simultanément
    max_active_doors = 500,
    
    -- Fréquence de mise à jour des portes proches
    update_nearby_doors_ms = 1000,
    
    -- Cache des vérifications d'autorisation
    auth_cache_duration = 30000, -- 30 secondes
    
    -- Limitation des événements réseau
    max_events_per_second = 10,
    
    -- Nettoyage automatique de la mémoire
    memory_cleanup_interval = 300000, -- 5 minutes
}

-- Configuration pour serveurs de développement
development {
    -- Tests automatiques au démarrage
    auto_run_tests = false,
    
    -- Logs détaillés
    verbose_logging = false,
    
    -- Rechargement à chaud de la config
    hot_reload_config = true,
    
    -- Interface de debug
    debug_ui = false,
}

-- Fin du manifest
print('^6[QB-DOORLOCK] Manifest chargé avec succès^7')
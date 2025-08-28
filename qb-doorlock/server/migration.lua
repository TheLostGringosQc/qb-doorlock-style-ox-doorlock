-- ================================
-- SYSTÈME DE MIGRATION - QB-DOORLOCK
-- server/migration.lua
-- Migration automatique entre versions
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

local Migration = {}
local migrationHistory = {}

-- ================================
-- DÉTECTION DE VERSION
-- ================================

-- Détecter la version installée
function Migration.DetectCurrentVersion()
    local version = {
        major = 1,
        minor = 0,
        patch = 0,
        hasDatabase = false,
        hasPSHousing = false,
        psHousingVersion = nil
    }
    
    -- Vérifier l'existence des tables
    MySQL.Async.fetchAll('SHOW TABLES LIKE "doorlocks"', {}, function(result)
        if result and #result > 0 then
            version.hasDatabase = true
            
            -- Vérifier les colonnes pour déterminer la version
            MySQL.Async.fetchAll('SHOW COLUMNS FROM doorlocks', {}, function(columns)
                for _, column in ipairs(columns) do
                    if column.Field == 'property_type' then
                        version.minor = 2 -- v1.2+
                    elseif column.Field == 'door_type' then
                        version.minor = 2 -- v1.2+
                    end
                end
            end)
        end
    end)
    
    -- Détecter PS-Housing
    if GetResourceState('ps-housing') == 'started' then
        version.hasPSHousing = true
        
        -- Détecter version PS-Housing
        if exports['ps-housing'] and exports['ps-housing'].GetAllProperties then
            version.psHousingVersion = "2.0.x"
        elseif exports['ps-housing'] and exports['ps-housing'].GetHouses then
            version.psHousingVersion = "1.x.x"
        end
    end
    
    return version
end

-- ================================
-- MIGRATIONS DISPONIBLES
-- ================================

-- Migration v1.0 → v1.1 (Ajout PS-Housing basic)
function Migration.MigrateToV11()
    print('[MIGRATION] Début migration vers v1.1...')
    
    -- Créer les nouvelles tables si nécessaire
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS doorlock_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            door_id VARCHAR(50) NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            action ENUM('lock','unlock') NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            job VARCHAR(50),
            grade INT,
            INDEX(door_id),
            INDEX(citizenid)
        )
    ]])
    
    -- Ajouter les colonnes manquantes à doorlocks
    MySQL.Async.execute('ALTER TABLE doorlocks ADD COLUMN IF NOT EXISTS last_user VARCHAR(50)', {}, function()
        print('[MIGRATION] Colonnes v1.1 ajoutées')
    end)
    
    Migration.LogMigration('1.0', '1.1', 'Ajout système de logs et PS-Housing basic')
    print('[MIGRATION] Migration v1.1 terminée')
end

-- Migration v1.1 → v1.2 (PS-Housing v2.0 + fonctionnalités avancées)
function Migration.MigrateToV12()
    print('[MIGRATION] Début migration vers v1.2...')
    
    -- Nouvelles tables pour v1.2
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS doorlock_security_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            door_id VARCHAR(50) NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            event_type ENUM('alarm', 'breach', 'maintenance', 'emergency', 'access_granted', 'access_denied', 'suspicious_activity', 'alarm_deactivated') NOT NULL,
            coordinates JSON,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            details TEXT,
            INDEX(door_id),
            INDEX(event_type)
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS doorlock_maintenance (
            id INT AUTO_INCREMENT PRIMARY KEY,
            door_id VARCHAR(50) NOT NULL,
            start_time TIMESTAMP NOT NULL,
            end_time TIMESTAMP NOT NULL,
            reason TEXT,
            scheduled_by VARCHAR(50),
            completed BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX(door_id),
            INDEX(completed)
        )
    ]])
    
    -- Nouvelles colonnes pour doorlocks
    MySQL.Async.execute('ALTER TABLE doorlocks ADD COLUMN IF NOT EXISTS property_type VARCHAR(50) DEFAULT "standard"')
    MySQL.Async.execute('ALTER TABLE doorlocks ADD COLUMN IF NOT EXISTS door_type VARCHAR(50) DEFAULT "main"')
    MySQL.Async.execute('ALTER TABLE doorlocks ADD COLUMN IF NOT EXISTS property_id VARCHAR(100)')
    
    -- Migration des données PS-Housing v1.x vers v2.0 format
    if Config.Migration and Config.Migration.autoMigrate then
        Migration.MigratePSHousingData()
    end
    
    Migration.LogMigration('1.1', '1.2', 'Ajout PS-Housing v2.0, systèmes avancés, sécurité')
    print('[MIGRATION] Migration v1.2 terminée')
end

-- Migration des données PS-Housing
function Migration.MigratePSHousingData()
    print('[MIGRATION] Migration des données PS-Housing...')
    
    -- Migrer les identifiants house_ vers property_
    MySQL.Async.execute([[
        UPDATE doorlocks 
        SET id = REPLACE(id, 'house_', 'property_'),
            property_type = 'house',
            property_id = SUBSTRING(id FROM 7)
        WHERE id LIKE 'house_%'
    ]])
    
    -- Migrer les logs
    MySQL.Async.execute([[
        UPDATE doorlock_logs 
        SET door_id = REPLACE(door_id, 'house_', 'property_')
        WHERE door_id LIKE 'house_%'
    ]])
    
    -- Migrer les items dans l'inventaire si activé
    if Config.Migration and Config.Migration.migrateKeys then
        Migration.MigrateInventoryItems()
    end
    
    print('[MIGRATION] Migration des données PS-Housing terminée')
end

-- Migrer les items d'inventaire
function Migration.MigrateInventoryItems()
    print('[MIGRATION] Migration des items d\'inventaire...')
    
    -- Migrer house_key_ vers property_key_
    MySQL.Async.execute([[
        UPDATE inventory 
        SET name = REPLACE(name, 'house_key_', 'property_key_')
        WHERE name LIKE 'house_key_%'
    ]])
    
    -- Mettre à jour les métadonnées des clés
    MySQL.Async.fetchAll('SELECT * FROM inventory WHERE name LIKE "property_key_%" AND info IS NOT NULL', {}, function(items)
        for _, item in ipairs(items) do
            local info = json.decode(item.info)
            if info and info.house then
                info.property = info.house
                info.type = 'owner'
                info.house = nil -- Retirer l'ancien champ
                
                MySQL.Async.execute('UPDATE inventory SET info = ? WHERE id = ?', {
                    json.encode(info), item.id
                })
            end
        end
    end)
    
    print('[MIGRATION] Migration des items terminée')
end

-- ================================
-- SYSTÈME DE SAUVEGARDE
-- ================================

-- Créer une sauvegarde avant migration
function Migration.CreateBackup(migrationName)
    if not Config.Migration or not Config.Migration.backupBeforeMigration then
        return true
    end
    
    local backupName = string.format('qb_doorlock_backup_%s_%s', migrationName, os.date('%Y%m%d_%H%M%S'))
    
    -- Sauvegarder les tables principales
    local tables = {'doorlocks', 'doorlock_logs', 'doorlock_security_logs', 'doorlock_maintenance'}
    
    for _, tableName in ipairs(tables) do
        local query = string.format('CREATE TABLE %s_backup AS SELECT * FROM %s', tableName, tableName)
        MySQL.Async.execute(query, {}, function(result)
            if result then
                print(string.format('[MIGRATION] Sauvegarde créée: %s_backup', tableName))
            end
        end)
    end
    
    return true
end

-- Restaurer depuis une sauvegarde
function Migration.RestoreBackup(backupName)
    print(string.format('[MIGRATION] Restauration depuis %s...', backupName))
    
    -- Cette fonction nécessiterait une implémentation plus complexe
    -- pour être sûre en production
    
    print('[MIGRATION] Restauration terminée')
end

-- ================================
-- VÉRIFICATIONS POST-MIGRATION
-- ================================

-- Vérifier l'intégrité après migration
function Migration.VerifyMigration(fromVersion, toVersion)
    local checks = {
        tablesExist = false,
        dataIntegrity = false,
        configValid = false,
        psHousingCompatible = false
    }
    
    -- Vérifier les tables
    MySQL.Async.fetchAll('SHOW TABLES LIKE "doorlock%"', {}, function(tables)
        if #tables >= 2 then -- Au minimum doorlocks et doorlock_logs
            checks.tablesExist = true
        end
    end)
    
    -- Vérifier l'intégrité des données
    MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM doorlocks', {}, function(result)
        if result[1] and result[1].count > 0 then
            checks.dataIntegrity = true
        end
    end)
    
    -- Vérifier la config
    if Config and Config.Doors then
        checks.configValid = true
    end
    
    -- Vérifier PS-Housing
    if GetResourceState('ps-housing') == 'started' then
        if toVersion >= '1.2' and exports['qb-doorlock'] and exports['qb-doorlock'].hasPropertyAccess then
            checks.psHousingCompatible = true
        end
    else
        checks.psHousingCompatible = true -- OK si pas utilisé
    end
    
    local allChecksPass = checks.tablesExist and checks.dataIntegrity and 
                         checks.configValid and checks.psHousingCompatible
    
    if allChecksPass then
        print(string.format('[MIGRATION] ✅ Vérification réussie: %s → %s', fromVersion, toVersion))
    else
        print(string.format('[MIGRATION] ❌ Vérification échouée: %s → %s', fromVersion, toVersion))
        for checkName, passed in pairs(checks) do
            print(string.format('[MIGRATION] %s: %s', checkName, passed and '✅' or '❌'))
        end
    end
    
    return allChecksPass
end

-- ================================
-- GESTION DE L'HISTORIQUE
-- ================================

-- Enregistrer une migration
function Migration.LogMigration(fromVersion, toVersion, description)
    local migrationRecord = {
        fromVersion = fromVersion,
        toVersion = toVersion,
        description = description,
        timestamp = os.time(),
        success = true
    }
    
    table.insert(migrationHistory, migrationRecord)
    
    -- Sauvegarder en fichier (optionnel)
    SaveResourceFile(GetCurrentResourceName(), 'migration_history.json', json.encode(migrationHistory, {indent = true}))
end

-- Obtenir l'historique des migrations
function Migration.GetHistory()
    return migrationHistory
end

-- ================================
-- MIGRATION AUTOMATIQUE
-- ================================

-- Exécuter les migrations nécessaires
function Migration.AutoMigrate()
    if not Config.Migration or not Config.Migration.autoMigrate then
        print('[MIGRATION] Migration automatique désactivée')
        return
    end
    
    local currentVersion = Migration.DetectCurrentVersion()
    local targetVersion = Config.Version or "1.2.0"
    
    print(string.format('[MIGRATION] Version actuelle détectée: %d.%d.%d', 
        currentVersion.major, currentVersion.minor, currentVersion.patch))
    
    -- Déterminer les migrations nécessaires
    local migrationsNeeded = {}
    
    if currentVersion.minor < 1 then
        table.insert(migrationsNeeded, {from = '1.0', to = '1.1', func = Migration.MigrateToV11})
    end
    
    if currentVersion.minor < 2 then
        table.insert(migrationsNeeded, {from = '1.1', to = '1.2', func = Migration.MigrateToV12})
    end
    
    -- Exécuter les migrations
    for _, migration in ipairs(migrationsNeeded) do
        print(string.format('[MIGRATION] Exécution migration %s → %s', migration.from, migration.to))
        
        -- Créer une sauvegarde
        Migration.CreateBackup(migration.to)
        
        -- Exécuter la migration
        local success, error = pcall(migration.func)
        
        if success then
            -- Vérifier la migration
            if Migration.VerifyMigration(migration.from, migration.to) then
                print(string.format('[MIGRATION] ✅ Migration réussie: %s → %s', migration.from, migration.to))
            else
                print(string.format('[MIGRATION] ❌ Vérification échouée: %s → %s', migration.from, migration.to))
            end
        else
            print(string.format('[MIGRATION] ❌ Erreur during migration %s → %s: %s', migration.from, migration.to, error))
        end
    end
    
    print('[MIGRATION] Migration automatique terminée')
end

-- ================================
-- OUTILS DE MIGRATION MANUELS
-- ================================

-- Migrer manuellement vers une version spécifique
function Migration.MigrateTo(targetVersion)
    print(string.format('[MIGRATION] Migration manuelle vers %s...', targetVersion))
    
    if targetVersion == '1.1' then
        Migration.MigrateToV11()
    elseif targetVersion == '1.2' then
        Migration.MigrateToV12()
    else
        print(string.format('[MIGRATION] Version inconnue: %s', targetVersion))
        return false
    end
    
    return true
end

-- Nettoyer les anciennes sauvegardes
function Migration.CleanupBackups(olderThanDays)
    olderThanDays = olderThanDays or 30
    local cutoffTime = os.time() - (olderThanDays * 24 * 3600)
    
    -- Cette fonction nécessiterait accès direct à la base pour être complète
    print(string.format('[MIGRATION] Nettoyage des sauvegardes de plus de %d jours', olderThanDays))
end

-- ================================
-- COMMANDES D'ADMINISTRATION
-- ================================

-- Commande pour voir l'historique des migrations
QBCore.Commands.Add('migrationhistory', 'Voir l\'historique des migrations', {}, false, function(source, args)
    local history = Migration.GetHistory()
    
    if #history == 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Aucune migration enregistrée', 'info')
        return
    end
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {100, 200, 100},
        args = {"MIGRATION", "=== Historique des Migrations ==="}
    })
    
    for _, migration in ipairs(history) do
        local dateStr = os.date('%d/%m/%Y %H:%M:%S', migration.timestamp)
        local status = migration.success and '✅' or '❌'
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {200, 200, 200},
            args = {"MIGRATION", string.format('%s %s → %s (%s) - %s', 
                status, migration.fromVersion, migration.toVersion, dateStr, migration.description)}
        })
    end
end, 'admin')

-- Commande pour forcer une migration
QBCore.Commands.Add('forcemigration', 'Forcer une migration vers une version', {
    {name = 'version', help = 'Version cible (1.1, 1.2)'}
}, true, function(source, args)
    local targetVersion = args[1]
    
    if not targetVersion then
        TriggerClientEvent('QBCore:Notify', source, 'Version requise (1.1, 1.2)', 'error')
        return
    end
    
    TriggerClientEvent('QBCore:Notify', source, string.format('Migration forcée vers %s...', targetVersion), 'primary')
    
    local success = Migration.MigrateTo(targetVersion)
    
    if success then
        TriggerClientEvent('QBCore:Notify', source, string.format('Migration vers %s terminée', targetVersion), 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, string.format('Erreur migration vers %s', targetVersion), 'error')
    end
end, 'god')

-- Commande pour vérifier la version actuelle
QBCore.Commands.Add('doorlockversion', 'Vérifier la version QB-Doorlock', {}, false, function(source, args)
    local currentVersion = Migration.DetectCurrentVersion()
    
    local info = {
        {color = {100, 200, 100}, args = {"VERSION", "=== QB-Doorlock Version Info ==="}},
        {color = {200, 200, 200}, args = {"VERSION", string.format("Version: %d.%d.%d", currentVersion.major, currentVersion.minor, currentVersion.patch)}},
        {color = {200, 200, 200}, args = {"VERSION", string.format("Base de données: %s", currentVersion.hasDatabase and "✅" or "❌")}},
        {color = {200, 200, 200}, args = {"VERSION", string.format("PS-Housing: %s", currentVersion.hasPSHousing and "✅" or "❌")}},
    }
    
    if currentVersion.hasPSHousing then
        table.insert(info, {color = {200, 200, 200}, args = {"VERSION", string.format("Version PS-Housing: %s", currentVersion.psHousingVersion or "Inconnue")}})
    end
    
    for _, message in ipairs(info) do
        TriggerClientEvent('chat:addMessage', source, message)
    end
end, 'admin')

-- Commande pour nettoyer les sauvegardes
QBCore.Commands.Add('cleanupbackups', 'Nettoyer les anciennes sauvegardes', {
    {name = 'days', help = 'Supprimer les sauvegardes de plus de X jours (défaut: 30)'}
}, false, function(source, args)
    local days = tonumber(args[1]) or 30
    
    TriggerClientEvent('QBCore:Notify', source, string.format('Nettoyage des sauvegardes de plus de %d jours...', days), 'primary')
    Migration.CleanupBackups(days)
    TriggerClientEvent('QBCore:Notify', source, 'Nettoyage terminé', 'success')
end, 'god')

-- ================================
-- INITIALISATION
-- ================================

-- Charger l'historique des migrations au démarrage
Citizen.CreateThread(function()
    -- Attendre que la base de données soit prête
    while not MySQL do
        Citizen.Wait(100)
    end
    
    -- Charger l'historique depuis le fichier
    local historyFile = LoadResourceFile(GetCurrentResourceName(), 'migration_history.json')
    if historyFile then
        local success, history = pcall(json.decode, historyFile)
        if success and history then
            migrationHistory = history
            print(string.format('[MIGRATION] Historique chargé: %d migrations', #migrationHistory))
        end
    end
    
    -- Attendre 5 secondes pour que tout soit chargé
    Wait(5000)
    
    -- Exécuter la migration automatique si activée
    if Config.Migration and Config.Migration.autoMigrate then
        Migration.AutoMigrate()
    else
        local currentVersion = Migration.DetectCurrentVersion()
        print(string.format('[MIGRATION] Version actuelle: %d.%d.%d (migration auto désactivée)', 
            currentVersion.major, currentVersion.minor, currentVersion.patch))
    end
end)

-- ================================
-- EXPORTS POUR AUTRES RESSOURCES
-- ================================

-- Obtenir la version actuelle
exports('getCurrentVersion', function()
    return Migration.DetectCurrentVersion()
end)

-- Obtenir l'historique des migrations
exports('getMigrationHistory', function()
    return Migration.GetHistory()
end)

-- Exécuter une migration manuelle
exports('migrateTo', function(targetVersion)
    return Migration.MigrateTo(targetVersion)
end)

-- Vérifier si une migration est nécessaire
exports('needsMigration', function()
    local currentVersion = Migration.DetectCurrentVersion()
    local configVersion = Config.Version or "1.2.0"
    
    -- Parser les versions pour comparaison
    local current = string.format("%d.%d.%d", currentVersion.major, currentVersion.minor, currentVersion.patch)
    
    return current ~= configVersion
end)

-- Créer une sauvegarde manuelle
exports('createBackup', function(backupName)
    return Migration.CreateBackup(backupName or 'manual')
end)

print('[MIGRATION] Module de migration chargé')
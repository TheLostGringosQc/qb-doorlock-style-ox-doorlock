-- ================================
-- SYSTÈMES AVANCÉS - QB-DOORLOCK
-- server/advanced_systems.lua
-- Fonctionnalités avancées (alarmes, maintenance, etc.)
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ================================
-- SYSTÈME D'ALARMES AVANCÉ
-- ================================

local AlarmSystem = {}
local activeAlarms = {}
local alarmCooldowns = {}

-- Déclencher une alarme
function AlarmSystem.TriggerAlarm(doorId, alarmType, triggeredBy)
    local door = Config.Doors[doorId]
    if not door or not door.hasAlarm then return end
    
    -- Vérifier le cooldown
    if alarmCooldowns[doorId] and (os.time() - alarmCooldowns[doorId]) < Config.AlarmSystem.cooldownTime then
        return
    end
    
    alarmCooldowns[doorId] = os.time()
    
    -- Créer l'alarme
    local alarm = {
        doorId = doorId,
        type = alarmType,
        triggeredBy = triggeredBy,
        location = door.objCoords,
        timestamp = os.time(),
        active = true
    }
    
    activeAlarms[doorId] = alarm
    
    -- Notifier les jobs autorisés
    AlarmSystem.NotifyAuthorizedPersonnel(alarm)
    
    -- Verrouiller automatiquement la porte
    doorStates[doorId] = true
    TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
    
    -- Log de sécurité
    MySQL.Async.execute('INSERT INTO doorlock_security_logs (door_id, citizenid, event_type, coordinates, details) VALUES (?, ?, ?, ?, ?)', {
        doorId,
        triggeredBy,
        alarmType,
        json.encode(door.objCoords),
        string.format('Alarme déclenchée: %s', alarmType)
    })
    
    -- Discord webhook si configuré
    if Config.DiscordWebhook then
        AlarmSystem.SendDiscordAlert(alarm)
    end
    
    print(string.format('[ALARM] Alarme déclenchée: %s à %s par %s', alarmType, doorId, triggeredBy))
end

-- Notifier le personnel autorisé
function AlarmSystem.NotifyAuthorizedPersonnel(alarm)
    local door = Config.Doors[alarm.doorId]
    local notifyJobs = Config.AlarmSystem.notifyJobs or door.authorizedJobs or {}
    
    for _, job in ipairs(notifyJobs) do
        local players = QBCore.Functions.GetQBPlayers()
        for _, player in pairs(players) do
            if player.PlayerData.job.name == job then
                -- Notification client avec blip
                TriggerClientEvent('qb-doorlock:client:alarmAlert', player.PlayerData.source, {
                    doorId = alarm.doorId,
                    location = alarm.location,
                    alarmType = alarm.type,
                    time = alarm.timestamp,
                    severity = 'high'
                })
                
                -- Notification QBCore
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 
                    string.format('🚨 ALARME: %s - %s', alarm.doorId, alarm.type), 'error', 15000)
            end
        end
    end
end

-- Désactiver une alarme
function AlarmSystem.DeactivateAlarm(doorId, deactivatedBy)
    if not activeAlarms[doorId] then return false end
    
    activeAlarms[doorId].active = false
    activeAlarms[doorId].deactivatedBy = deactivatedBy
    activeAlarms[doorId].deactivatedAt = os.time()
    
    -- Log de désactivation
    MySQL.Async.execute('INSERT INTO doorlock_security_logs (door_id, citizenid, event_type, details) VALUES (?, ?, ?, ?)', {
        doorId,
        deactivatedBy,
        'alarm_deactivated',
        'Alarme désactivée manuellement'
    })
    
    -- Notifier les clients
    TriggerClientEvent('qb-doorlock:client:alarmDeactivated', -1, doorId)
    
    return true
end

-- Webhook Discord pour alarmes
function AlarmSystem.SendDiscordAlert(alarm)
    if not Config.DiscordWebhook then return end
    
    local embed = {
        {
            color = 16711680, -- Rouge
            title = "🚨 ALARME DE SÉCURITÉ",
            description = string.format("**Porte:** %s\n**Type:** %s\n**Heure:** %s\n**Coordonnées:** %s",
                alarm.doorId,
                alarm.type,
                os.date("%d/%m/%Y %H:%M:%S", alarm.timestamp),
                string.format("%.2f, %.2f, %.2f", alarm.location.x, alarm.location.y, alarm.location.z)
            ),
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = {
                text = "QB-Doorlock Security System"
            }
        }
    }
    
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', 
        json.encode({embeds = embed}), 
        {['Content-Type'] = 'application/json'}
    )
end

-- ================================
-- SYSTÈME DE MAINTENANCE
-- ================================

local MaintenanceSystem = {}
local maintenanceSchedule = {}
local doorIssues = {}

-- Programmer une maintenance
function MaintenanceSystem.ScheduleMaintenance(doorId, startTime, endTime, reason, scheduledBy)
    local maintenanceId = string.format('%s_%d', doorId, os.time())
    
    maintenanceSchedule[maintenanceId] = {
        doorId = doorId,
        startTime = startTime,
        endTime = endTime,
        reason = reason,
        scheduledBy = scheduledBy,
        status = 'scheduled',
        created = os.time()
    }
    
    -- Sauvegarder en base
    MySQL.Async.execute('INSERT INTO doorlock_maintenance (door_id, start_time, end_time, reason, scheduled_by) VALUES (?, ?, ?, ?, ?)', {
        doorId,
        os.date('%Y-%m-%d %H:%M:%S', startTime),
        os.date('%Y-%m-%d %H:%M:%S', endTime),
        reason,
        scheduledBy
    })
    
    print(string.format('[MAINTENANCE] Maintenance programmée: %s de %s à %s', doorId, 
        os.date('%d/%m %H:%M', startTime), 
        os.date('%d/%m %H:%M', endTime)))
    
    return maintenanceId
end

-- Signaler un problème
function MaintenanceSystem.ReportIssue(doorId, issueType, description, reportedBy)
    local issueId = string.format('%s_%s_%d', doorId, issueType, os.time())
    
    doorIssues[issueId] = {
        doorId = doorId,
        issueType = issueType,
        description = description,
        reportedBy = reportedBy,
        status = 'open',
        priority = MaintenanceSystem.CalculatePriority(issueType),
        reported = os.time()
    }
    
    -- Notifier les techniciens si problème critique
    if doorIssues[issueId].priority == 'critical' then
        MaintenanceSystem.NotifyTechnicians(doorIssues[issueId])
    end
    
    return issueId
end

-- Calculer la priorité d'un problème
function MaintenanceSystem.CalculatePriority(issueType)
    local priorities = {
        door_stuck = 'high',
        lock_malfunction = 'high',
        keypad_error = 'medium',
        sensor_failure = 'medium',
        cosmetic_damage = 'low',
        noise_issue = 'low'
    }
    
    return priorities[issueType] or 'medium'
end

-- Notifier les techniciens
function MaintenanceSystem.NotifyTechnicians(issue)
    local techJobs = Config.Maintenance.allowedJobs or {'mechanic'}
    
    for _, job in ipairs(techJobs) do
        local players = QBCore.Functions.GetQBPlayers()
        for _, player in pairs(players) do
            if player.PlayerData.job.name == job then
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source,
                    string.format('🔧 Intervention requise: %s - %s', issue.doorId, issue.issueType),
                    'primary', 10000)
            end
        end
    end
end

-- Réparer une porte
function MaintenanceSystem.RepairDoor(doorId, repairType, repairedBy)
    local Player = QBCore.Functions.GetPlayer(repairedBy)
    if not Player then return false end
    
    -- Vérifier le job
    local allowedJobs = Config.Maintenance.allowedJobs or {'mechanic'}
    local hasPermission = false
    
    for _, job in ipairs(allowedJobs) do
        if Player.PlayerData.job.name == job then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        TriggerClientEvent('QBCore:Notify', repairedBy, 'Vous n\'êtes pas autorisé à effectuer des réparations', 'error')
        return false
    end
    
    -- Effectuer la réparation
    local repairCost = Config.Maintenance.repairCost or 250
    Player.Functions.AddMoney('cash', repairCost, 'door-repair')
    
    -- Remettre la porte en état normal
    doorStates[doorId] = true
    TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
    
    -- Résoudre les problèmes liés
    for issueId, issue in pairs(doorIssues) do
        if issue.doorId == doorId and issue.status == 'open' then
            issue.status = 'resolved'
            issue.resolvedBy = Player.PlayerData.citizenid
            issue.resolvedAt = os.time()
        end
    end
    
    -- Log de réparation
    MySQL.Async.execute('INSERT INTO doorlock_logs (door_id, citizenid, action, job, grade) VALUES (?, ?, ?, ?, ?)', {
        doorId,
        Player.PlayerData.citizenid,
        'repair',
        Player.PlayerData.job.name,
        Player.PlayerData.job.grade.level
    })
    
    TriggerClientEvent('QBCore:Notify', repairedBy, 
        string.format('Réparation terminée - $%d reçus', repairCost), 'success')
    
    return true
end

-- ================================
-- SYSTÈME DE MULTI-CLÉS AVANCÉ
-- ================================

local MultiKeySystem = {}
local multiKeySessions = {}

-- Initier un accès multi-clés
function MultiKeySystem.InitiateMultiKeyAccess(doorId, playerId)
    local door = Config.Doors[doorId]
    if not door or not door.requiresMultipleKeys then return false end
    
    local sessionId = doorId .. '_' .. os.time()
    
    multiKeySessions[sessionId] = {
        doorId = doorId,
        requiredKeys = door.keyHolders or 2,
        activeKeys = {},
        initiatedBy = playerId,
        startTime = os.time(),
        timeout = 300 -- 5 minutes
    }
    
    -- Ajouter la première clé
    table.insert(multiKeySessions[sessionId].activeKeys, playerId)
    
    -- Notifier les clients
    TriggerClientEvent('qb-doorlock:client:multiKeyUpdate', -1, doorId, 
        multiKeySessions[sessionId].activeKeys, 
        multiKeySessions[sessionId].requiredKeys)
    
    return sessionId
end

-- Ajouter une clé à une session multi-clés
function MultiKeySystem.AddKey(sessionId, playerId)
    local session = multiKeySessions[sessionId]
    if not session then return false end
    
    -- Vérifier si le joueur n'a pas déjà ajouté sa clé
    for _, existingPlayerId in ipairs(session.activeKeys) do
        if existingPlayerId == playerId then
            return false
        end
    end
    
    table.insert(session.activeKeys, playerId)
    
    -- Vérifier si toutes les clés sont présentes
    if #session.activeKeys >= session.requiredKeys then
        MultiKeySystem.CompleteMultiKeyAccess(sessionId)
    else
        -- Mettre à jour l'interface
        TriggerClientEvent('qb-doorlock:client:multiKeyUpdate', -1, session.doorId,
            session.activeKeys, session.requiredKeys)
    end
    
    return true
end

-- Compléter l'accès multi-clés
function MultiKeySystem.CompleteMultiKeyAccess(sessionId)
    local session = multiKeySessions[sessionId]
    if not session then return end
    
    -- Détecter les tentatives suspectes
    if not success then
        SurveillanceSystem.CheckSuspiciousActivity(doorId, Player.PlayerData.citizenid)
    end
end

-- Détecter les activités suspectes
function SurveillanceSystem.CheckSuspiciousActivity(doorId, citizenid)
    -- Compter les tentatives échouées dans les 10 dernières minutes
    MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM doorlock_security_logs WHERE door_id = ? AND citizenid = ? AND event_type = "access_denied" AND timestamp > DATE_SUB(NOW(), INTERVAL 10 MINUTE)', {
        doorId, citizenid
    }, function(result)
        if result[1] and result[1].count >= 3 then
            -- Déclencher une alarme pour tentatives répétées
            AlarmSystem.TriggerAlarm(doorId, 'suspicious_activity', citizenid)
        end
    end)
end

-- ================================
-- ÉVÉNEMENTS SERVEUR
-- ================================

-- Déclencher une alarme manuellement
RegisterNetEvent('qb-doorlock:server:triggerAlarm')
AddEventHandler('qb-doorlock:server:triggerAlarm', function(doorId, alarmType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        AlarmSystem.TriggerAlarm(doorId, alarmType, Player.PlayerData.citizenid)
    end
end)

-- Désactiver une alarme
RegisterNetEvent('qb-doorlock:server:deactivateAlarm')
AddEventHandler('qb-doorlock:server:deactivateAlarm', function(doorId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local success = AlarmSystem.DeactivateAlarm(doorId, Player.PlayerData.citizenid)
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Alarme désactivée', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Aucune alarme active', 'error')
        end
    end
end)

-- Programmer une maintenance
RegisterNetEvent('qb-doorlock:server:scheduleMaintenance')
AddEventHandler('qb-doorlock:server:scheduleMaintenance', function(doorId, scheduleData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local maintenanceId = MaintenanceSystem.ScheduleMaintenance(
        doorId,
        scheduleData.startTime,
        scheduleData.endTime,
        scheduleData.reason,
        Player.PlayerData.citizenid
    )
    
    TriggerClientEvent('QBCore:Notify', src, 
        string.format('Maintenance programmée: %s', maintenanceId), 'success')
end)

-- Signaler un problème
RegisterNetEvent('qb-doorlock:server:reportIssue')
AddEventHandler('qb-doorlock:server:reportIssue', function(doorId, issueData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local issueId = MaintenanceSystem.ReportIssue(
        doorId,
        issueData.type,
        issueData.description,
        Player.PlayerData.citizenid
    )
    
    TriggerClientEvent('QBCore:Notify', src, 
        string.format('Problème signalé: %s', issueId), 'success')
end)

-- Réparer une porte
RegisterNetEvent('qb-doorlock:server:repairDoor')
AddEventHandler('qb-doorlock:server:repairDoor', function(doorId, repairType)
    local src = source
    
    local success = MaintenanceSystem.RepairDoor(doorId, repairType, src)
    if not success then
        TriggerClientEvent('QBCore:Notify', src, 'Réparation échouée', 'error')
    end
end)

-- Initier un accès multi-clés
RegisterNetEvent('qb-doorlock:server:initiateMultiKey')
AddEventHandler('qb-doorlock:server:initiateMultiKey', function(doorId)
    local src = source
    
    local sessionId = MultiKeySystem.InitiateMultiKeyAccess(doorId, src)
    if sessionId then
        TriggerClientEvent('QBCore:Notify', src, 'Session multi-clés initiée', 'primary')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Impossible d\'initier la session', 'error')
    end
end)

-- Utiliser une clé dans un système multi-clés
RegisterNetEvent('qb-doorlock:server:useMultiKey')
AddEventHandler('qb-doorlock:server:useMultiKey', function(doorId, keyType)
    local src = source
    
    -- Trouver la session active pour cette porte
    local activeSession = nil
    for sessionId, session in pairs(multiKeySessions) do
        if session.doorId == doorId then
            activeSession = sessionId
            break
        end
    end
    
    if activeSession then
        local success = MultiKeySystem.AddKey(activeSession, src)
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Clé ajoutée au système', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Clé déjà utilisée', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Aucune session multi-clés active', 'error')
    end
end)

-- ================================
-- THREADS ET AUTOMATISATIONS
-- ================================

-- Thread de nettoyage des sessions expirées
Citizen.CreateThread(function()
    while true do
        Wait(30000) -- Vérifier toutes les 30 secondes
        
        local currentTime = os.time()
        
        -- Nettoyer les sessions multi-clés expirées
        for sessionId, session in pairs(multiKeySessions) do
            if currentTime - session.startTime > session.timeout then
                -- Notifier les participants de l'expiration
                for _, playerId in ipairs(session.activeKeys) do
                    TriggerClientEvent('QBCore:Notify', playerId, 
                        'Session multi-clés expirée', 'error')
                end
                
                multiKeySessions[sessionId] = nil
                print(string.format('[MULTI-KEY] Session expirée: %s', sessionId))
            end
        end
        
        -- Nettoyer les alarmes anciennes
        for doorId, alarm in pairs(activeAlarms) do
            if currentTime - alarm.timestamp > 3600 then -- 1 heure
                activeAlarms[doorId] = nil
            end
        end
    end
end)

-- Thread de maintenance automatique
Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Vérifier chaque minute
        
        local currentTime = os.time()
        
        -- Vérifier les maintenances programmées
        for maintenanceId, maintenance in pairs(maintenanceSchedule) do
            if maintenance.status == 'scheduled' and currentTime >= maintenance.startTime then
                maintenance.status = 'in_progress'
                
                -- Notifier le début de la maintenance
                local techJobs = Config.Maintenance.allowedJobs or {'mechanic'}
                for _, job in ipairs(techJobs) do
                    local players = QBCore.Functions.GetQBPlayers()
                    for _, player in pairs(players) do
                        if player.PlayerData.job.name == job then
                            TriggerClientEvent('QBCore:Notify', player.PlayerData.source,
                                string.format('🔧 Maintenance débutée: %s', maintenance.doorId),
                                'primary')
                        end
                    end
                end
                
                -- Verrouiller la porte en maintenance
                doorStates[maintenance.doorId] = true
                TriggerClientEvent('qb-doorlock:client:setState', -1, maintenance.doorId, true)
            elseif maintenance.status == 'in_progress' and currentTime >= maintenance.endTime then
                maintenance.status = 'completed'
                
                -- Marquer comme terminé en base
                MySQL.Async.execute('UPDATE doorlock_maintenance SET completed = 1 WHERE door_id = ? AND start_time = ?', {
                    maintenance.doorId,
                    os.date('%Y-%m-%d %H:%M:%S', maintenance.startTime)
                })
            end
        end
    end
end)

-- Thread de surveillance des performances
Citizen.CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        -- Statistiques de performance
        local stats = {
            totalDoors = 0,
            lockedDoors = 0,
            activeAlarms = 0,
            activeSessions = 0,
            openIssues = 0
        }
        
        -- Compter les portes
        for doorId, _ in pairs(Config.Doors) do
            stats.totalDoors = stats.totalDoors + 1
            if doorStates[doorId] then
                stats.lockedDoors = stats.lockedDoors + 1
            end
        end
        
        -- Compter les alarmes actives
        for _, alarm in pairs(activeAlarms) do
            if alarm.active then
                stats.activeAlarms = stats.activeAlarms + 1
            end
        end
        
        -- Compter les sessions actives
        for _, _ in pairs(multiKeySessions) do
            stats.activeSessions = stats.activeSessions + 1
        end
        
        -- Compter les problèmes ouverts
        for _, issue in pairs(doorIssues) do
            if issue.status == 'open' then
                stats.openIssues = stats.openIssues + 1
            end
        end
        
        -- Log des statistiques (développement)
        if Config.Debug then
            print(string.format('[QB-DOORLOCK] Stats: %d portes, %d verrouillées, %d alarmes, %d sessions, %d problèmes',
                stats.totalDoors, stats.lockedDoors, stats.activeAlarms, stats.activeSessions, stats.openIssues))
        end
    end
end)

-- ================================
-- EXPORTS POUR AUTRES RESSOURCES
-- ================================

-- Système d'alarmes
exports('triggerAlarm', function(doorId, alarmType, triggeredBy)
    return AlarmSystem.TriggerAlarm(doorId, alarmType, triggeredBy)
end)

exports('deactivateAlarm', function(doorId, deactivatedBy)
    return AlarmSystem.DeactivateAlarm(doorId, deactivatedBy)
end)

exports('getActiveAlarms', function()
    return activeAlarms
end)

-- Système de maintenance
exports('scheduleMaintenance', function(doorId, startTime, endTime, reason, scheduledBy)
    return MaintenanceSystem.ScheduleMaintenance(doorId, startTime, endTime, reason, scheduledBy)
end)

exports('reportIssue', function(doorId, issueType, description, reportedBy)
    return MaintenanceSystem.ReportIssue(doorId, issueType, description, reportedBy)
end)

exports('repairDoor', function(doorId, repairType, repairedBy)
    return MaintenanceSystem.RepairDoor(doorId, repairType, repairedBy)
end)

exports('getMaintenanceHistory', function(doorId)
    return MySQL.Sync.fetchAll('SELECT * FROM doorlock_maintenance WHERE door_id = ? ORDER BY start_time DESC LIMIT 10', {doorId})
end)

exports('getCurrentIssues', function(doorId)
    local issues = {}
    for issueId, issue in pairs(doorIssues) do
        if issue.doorId == doorId and issue.status == 'open' then
            table.insert(issues, issue)
        end
    end
    return issues
end)

-- Système multi-clés
exports('initiateMultiKeyAccess', function(doorId, playerId)
    return MultiKeySystem.InitiateMultiKeyAccess(doorId, playerId)
end)

exports('addMultiKey', function(sessionId, playerId)
    return MultiKeySystem.AddKey(sessionId, playerId)
end)

exports('getMultiKeySessions', function()
    return multiKeySessions
end)

-- Système de surveillance
exports('logAccessAttempt', function(doorId, playerId, success, method)
    return SurveillanceSystem.LogAttempt(doorId, playerId, success, method)
end)

exports('getSecurityLogs', function(doorId, limit)
    limit = limit or 50
    return MySQL.Sync.fetchAll('SELECT * FROM doorlock_security_logs WHERE door_id = ? ORDER BY timestamp DESC LIMIT ?', {doorId, limit})
end)

-- ================================
-- COMMANDES D'ADMINISTRATION AVANCÉES
-- ================================

-- Commande pour voir les alarmes actives
QBCore.Commands.Add('activealarms', 'Voir les alarmes actives', {}, false, function(source, args)
    local alarmCount = 0
    for doorId, alarm in pairs(activeAlarms) do
        if alarm.active then
            alarmCount = alarmCount + 1
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 100, 100},
                args = {"ALARME", string.format("%s - %s (%s)", doorId, alarm.type, os.date("%H:%M:%S", alarm.timestamp))}
            })
        end
    end
    
    if alarmCount == 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Aucune alarme active', 'success')
    end
end, 'admin')

-- Commande pour forcer une alarme (test)
QBCore.Commands.Add('testalarm', 'Déclencher une alarme de test', {
    {name = 'doorId', help = 'ID de la porte'},
    {name = 'type', help = 'Type d\'alarme (optionnel)'}
}, true, function(source, args)
    local doorId = args[1]
    local alarmType = args[2] or 'test'
    
    if Config.Doors[doorId] then
        AlarmSystem.TriggerAlarm(doorId, alarmType, 'ADMIN_TEST')
        TriggerClientEvent('QBCore:Notify', source, string.format('Alarme de test déclenchée: %s', doorId), 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Porte introuvable', 'error')
    end
end, 'admin')

-- Commande pour voir les statistiques du système
QBCore.Commands.Add('doorstats', 'Statistiques du système de portes', {}, false, function(source, args)
    local totalDoors = 0
    local lockedDoors = 0
    local activeSessions = 0
    local activeAlarms = 0
    
    for doorId, _ in pairs(Config.Doors) do
        totalDoors = totalDoors + 1
        if doorStates[doorId] then
            lockedDoors = lockedDoors + 1
        end
    end
    
    for _, _ in pairs(multiKeySessions) do
        activeSessions = activeSessions + 1
    end
    
    for _, alarm in pairs(activeAlarms) do
        if alarm.active then
            activeAlarms = activeAlarms + 1
        end
    end
    
    local messages = {
        {color = {100, 200, 100}, args = {"STATS", "=== Statistiques QB-Doorlock ==="}},
        {color = {200, 200, 200}, args = {"STATS", string.format("Portes totales: %d", totalDoors)}},
        {color = {200, 200, 200}, args = {"STATS", string.format("Portes verrouillées: %d", lockedDoors)}},
        {color = {200, 200, 200}, args = {"STATS", string.format("Sessions multi-clés: %d", activeSessions)}},
        {color = {200, 200, 200}, args = {"STATS", string.format("Alarmes actives: %d", activeAlarms)}}
    }
    
    for _, message in ipairs(messages) do
        TriggerClientEvent('chat:addMessage', source, message)
    end
end, 'admin')

print('[ADVANCED-SYSTEMS] Module de systèmes avancés chargé')verrouiller la porte
    doorStates[session.doorId] = false
    TriggerClientEvent('qb-doorlock:client:setState', -1, session.doorId, false)
    
    -- Notifier tous les participants
    for _, playerId in ipairs(session.activeKeys) do
        TriggerClientEvent('QBCore:Notify', playerId, 
            'Accès multi-clés autorisé', 'success')
    end
    
    -- Log de l'événement
    MySQL.Async.execute('INSERT INTO doorlock_logs (door_id, citizenid, action, details) VALUES (?, ?, ?, ?)', {
        session.doorId,
        session.initiatedBy,
        'multi_key_access',
        string.format('Accès avec %d clés', #session.activeKeys)
    })
    
    -- Nettoyer la session
    multiKeySessions[sessionId] = nil
end

-- ================================
-- SYSTÈME DE SURVEILLANCE
-- ================================

local SurveillanceSystem = {}

-- Surveiller les tentatives d'accès
function SurveillanceSystem.LogAttempt(doorId, playerId, success, method)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end
    
    -- Log détaillé
    MySQL.Async.execute('INSERT INTO doorlock_security_logs (door_id, citizenid, event_type, details) VALUES (?, ?, ?, ?)', {
        doorId,
        Player.PlayerData.citizenid,
        success and 'access_granted' or 'access_denied',
        string.format('Méthode: %s, Job: %s, Grade: %d', method, Player.PlayerData.job.name, Player.PlayerData.job.grade.level)
    })
    
    -- Dé
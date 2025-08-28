-- ================================
-- SERVER MAIN - QB-DOORLOCK
-- server/main.lua
-- Script serveur principal
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables globales
local doorStates = {}
local doorCooldowns = {}

-- ================================
-- FONCTIONS UTILITAIRES
-- ================================

-- Fonctions utilitaires pour les portes
local DoorLockUtils = {}

-- Charger les états des portes depuis la base
function DoorLockUtils.LoadDoorStates()
    MySQL.Async.fetchAll('SELECT * FROM doorlocks', {}, function(result)
        if result then
            for _, door in ipairs(result) do
                doorStates[door.id] = door.locked == 1
            end
            print(string.format('[QB-DOORLOCK] %d états de portes chargés', #result))
        end
    end)
end

-- Sauvegarder l'état d'une porte
function DoorLockUtils.SaveDoorState(doorId, locked, citizenid)
    MySQL.Async.execute('INSERT INTO doorlocks (id, locked, last_user) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE locked = ?, last_user = ?, last_updated = NOW()', {
        doorId, locked and 1 or 0, citizenid, locked and 1 or 0, citizenid
    })
end

-- Logger l'activité
function DoorLockUtils.LogActivity(doorId, citizenid, action, job, grade, method)
    method = method or 'manual'
    MySQL.Async.execute('INSERT INTO doorlock_logs (door_id, citizenid, action, job, grade, method) VALUES (?, ?, ?, ?, ?, ?)', {
        doorId, citizenid, action, job, grade, method
    })
end

-- Obtenir les logs d'une porte
function DoorLockUtils.GetDoorLogs(doorId, limit)
    limit = limit or 50
    return MySQL.Sync.fetchAll('SELECT * FROM doorlock_logs WHERE door_id = ? ORDER BY timestamp DESC LIMIT ?', {doorId, limit})
end

-- Nettoyer les anciens logs
function DoorLockUtils.CleanOldLogs(days)
    days = days or 30
    MySQL.Async.execute('DELETE FROM doorlock_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL ? DAY)', {days}, function(affectedRows)
        print(string.format('[QB-DOORLOCK] %d anciens logs supprimés', affectedRows))
    end)
end

-- Vérifier si un joueur a un grade suffisant
function DoorLockUtils.HasRequiredGrade(Player, door)
    if not door.authorizedGrades then return true end
    
    local playerGrade = Player.PlayerData.job.grade.level
    
    for _, requiredGrade in ipairs(door.authorizedGrades) do
        if playerGrade >= requiredGrade then
            return true
        end
    end
    
    return false
end

-- Vérifier les horaires d'ouverture
function DoorLockUtils.IsWithinSchedule(door)
    if not door.schedule then return true end
    
    local currentHour = tonumber(os.date("%H"))
    return currentHour >= door.schedule.openHour and currentHour < door.schedule.closeHour
end

-- Vérifier le cooldown
function DoorLockUtils.IsOnCooldown(source, doorId)
    local key = source .. '_' .. doorId
    local now = GetGameTimer()
    
    if doorCooldowns[key] and (now - doorCooldowns[key]) < 2000 then -- 2 secondes
        return true
    end
    
    doorCooldowns[key] = now
    return false
end

-- ================================
-- FONCTIONS D'AUTORISATION
-- ================================

-- Vérifier l'autorisation d'accès à une porte
local function IsAuthorized(source, doorId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local door = Config.Doors[doorId]
    if not door then return false end
    
    -- Vérification du job
    if door.authorizedJobs then
        local hasJob = false
        for _, job in ipairs(door.authorizedJobs) do
            if Player.PlayerData.job.name == job then
                hasJob = true
                break
            end
        end
        if not hasJob then return false end
    end
    
    -- Vérification du grade
    if not DoorLockUtils.HasRequiredGrade(Player, door) then
        return false
    end
    
    -- Vérification des items requis
    if door.requiredItems then
        for _, requiredItem in ipairs(door.requiredItems) do
            local hasItem = Player.Functions.GetItemByName(requiredItem.item)
            if not hasItem or hasItem.amount < 1 then
                return false
            end
        end
    end
    
    -- Vérification des horaires
    if not DoorLockUtils.IsWithinSchedule(door) then
        return false
    end
    
    return true
end

-- ================================
-- ÉVÉNEMENTS SERVEUR
-- ================================

-- Event pour mettre à jour l'état d'une porte
RegisterNetEvent('qb-doorlock:server:updateState')
AddEventHandler('qb-doorlock:server:updateState', function(doorId, state)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Vérifier le cooldown
    if DoorLockUtils.IsOnCooldown(src, doorId) then
        TriggerClientEvent('QBCore:Notify', src, 'Attendez avant d\'interagir à nouveau', 'error')
        return
    end
    
    -- Vérifier l'autorisation
    if not IsAuthorized(src, doorId) then
        TriggerClientEvent('QBCore:Notify', src, 'Vous n\'avez pas l\'autorisation', 'error')
        return
    end
    
    local door = Config.Doors[doorId]
    if not door then return end
    
    -- Retirer les items si nécessaire
    if door.requiredItems then
        for _, requiredItem in ipairs(door.requiredItems) do
            if requiredItem.remove then
                Player.Functions.RemoveItem(requiredItem.item, 1)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[requiredItem.item], "remove")
            end
        end
    end
    
    -- Mettre à jour l'état
    doorStates[doorId] = state
    
    -- Sauvegarder en base
    DoorLockUtils.SaveDoorState(doorId, state, Player.PlayerData.citizenid)
    
    -- Logger l'activité
    DoorLockUtils.LogActivity(doorId, Player.PlayerData.citizenid, state and 'lock' or 'unlock', 
        Player.PlayerData.job.name, Player.PlayerData.job.grade.level)
    
    -- Synchroniser avec tous les clients
    TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, state)
    
    -- Notification
    local lockState = state and 'verrouillée' or 'déverrouillée'
    TriggerClientEvent('QBCore:Notify', src, string.format('Porte %s', lockState), 'success')
end)

-- Event pour toggle une porte
RegisterNetEvent('qb-doorlock:server:toggleLock')
AddEventHandler('qb-doorlock:server:toggleLock', function(doorId)
    local src = source
    
    local currentState = doorStates[doorId]
    if currentState == nil then
        local door = Config.Doors[doorId]
        currentState = door and door.locked or false
    end
    
    TriggerEvent('qb-doorlock:server:updateState', doorId, not currentState)
end)

-- Event pour vérifier un code d'accès
RegisterNetEvent('qb-doorlock:server:checkCode')
AddEventHandler('qb-doorlock:server:checkCode', function(doorId, code)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local door = Config.Doors[doorId]
    if not door or not door.requiresCode then
        TriggerClientEvent('qb-doorlock:client:codeResult', src, false, doorId)
        return
    end
    
    -- Vérifier le code
    local isCorrect = (code == door.securityCode)
    
    if isCorrect then
        -- Code correct, toggle la porte
        local currentState = doorStates[doorId] or door.locked
        doorStates[doorId] = not currentState
        
        -- Sauvegarder et logger
        DoorLockUtils.SaveDoorState(doorId, not currentState, Player.PlayerData.citizenid)
        DoorLockUtils.LogActivity(doorId, Player.PlayerData.citizenid, 
            not currentState and 'lock' or 'unlock', 
            Player.PlayerData.job.name, Player.PlayerData.job.grade.level, 'code')
        
        -- Synchroniser
        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, not currentState)
    else
        -- Code incorrect, logger la tentative
        MySQL.Async.execute('INSERT INTO doorlock_security_logs (door_id, citizenid, event_type, details, severity) VALUES (?, ?, ?, ?, ?)', {
            doorId, Player.PlayerData.citizenid, 'access_denied', 'Code incorrect saisi', 'medium'
        })
    end
    
    TriggerClientEvent('qb-doorlock:client:codeResult', src, isCorrect, doorId)
end)

-- Event pour toggle un groupe de portes
RegisterNetEvent('qb-doorlock:server:toggleGroup')
AddEventHandler('qb-doorlock:server:toggleGroup', function(groupId, doorId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local group = Config.DoorGroups[groupId]
    if not group then return end
    
    -- Vérifier l'autorisation pour le groupe
    local hasJob = false
    if group.authorizedJobs then
        for _, job in ipairs(group.authorizedJobs) do
            if Player.PlayerData.job.name == job then
                hasJob = true
                break
            end
        end
    end
    
    if not hasJob then
        TriggerClientEvent('QBCore:Notify', src, 'Vous n\'avez pas l\'autorisation pour ce groupe', 'error')
        return
    end
    
    -- Vérifier le grade si requis
    if group.requiredGrade and Player.PlayerData.job.grade.level < group.requiredGrade then
        TriggerClientEvent('QBCore:Notify', src, 'Grade insuffisant', 'error')
        return
    end
    
    -- Toggle toutes les portes du groupe
    for _, groupDoorId in ipairs(group.doors) do
        if Config.Doors[groupDoorId] then
            local currentState = doorStates[groupDoorId] or Config.Doors[groupDoorId].locked
            doorStates[groupDoorId] = not currentState
            
            -- Sauvegarder et synchroniser chaque porte
            DoorLockUtils.SaveDoorState(groupDoorId, not currentState, Player.PlayerData.citizenid)
            DoorLockUtils.LogActivity(groupDoorId, Player.PlayerData.citizenid, 
                not currentState and 'lock' or 'unlock', 
                Player.PlayerData.job.name, Player.PlayerData.job.grade.level, 'group')
            TriggerClientEvent('qb-doorlock:client:setState', -1, groupDoorId, not currentState)
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src, string.format('Groupe %s activé', groupId), 'success')
end)

-- ================================
-- CALLBACKS
-- ================================

-- Callback pour obtenir l'état des portes
QBCore.Functions.CreateCallback('qb-doorlock:server:getDoorStates', function(source, cb)
    cb(doorStates)
end)

-- Callback pour obtenir les logs d'une porte
QBCore.Functions.CreateCallback('qb-doorlock:server:getDoorLogs', function(source, cb, doorId, limit)
    local logs = DoorLockUtils.GetDoorLogs(doorId, limit)
    cb(logs)
end)

-- ================================
-- COMMANDES D'ADMINISTRATION
-- ================================

-- Commande pour forcer l'état d'une porte
QBCore.Commands.Add('adoorlock', 'Forcer le verrouillage/déverrouillage d\'une porte (Admin)', {
    {name = 'doorId', help = 'ID de la porte'},
    {name = 'state', help = 'true/false'}
}, true, function(source, args)
    local doorId = args[1]
    local state = args[2] == 'true'
    
    if Config.Doors[doorId] then
        doorStates[doorId] = state
        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, state)
        DoorLockUtils.SaveDoorState(doorId, state, 'ADMIN')
        TriggerClientEvent('QBCore:Notify', source, string.format('Porte %s %s', doorId, state and 'verrouillée' or 'déverrouillée'), 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'ID de porte invalide', 'error')
    end
end, 'admin')

-- Commande pour voir les logs d'une porte
QBCore.Commands.Add('doorlogs', 'Voir les logs d\'une porte', {
    {name = 'doorId', help = 'ID de la porte'}
}, true, function(source, args)
    local doorId = args[1]
    
    if not doorId or not Config.Doors[doorId] then
        TriggerClientEvent('QBCore:Notify', source, 'ID de porte invalide', 'error')
        return
    end
    
    local logs = DoorLockUtils.GetDoorLogs(doorId, 10)
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {255, 255, 0},
        multiline = true,
        args = {"SYSTÈME", string.format("Logs pour la porte %s:", doorId)}
    })
    
    for _, log in ipairs(logs) do
        TriggerClientEvent('chat:addMessage', source, {
            color = {200, 200, 200},
            args = {"", string.format("%s - %s - %s (%s)", log.timestamp, log.citizenid, log.action, log.job)}
        })
    end
end, 'admin')

-- Commande pour nettoyer les logs
QBCore.Commands.Add('cleandoorlogs', 'Nettoyer les anciens logs de portes', {
    {name = 'days', help = 'Nombre de jours à conserver (défaut: 30)'}
}, false, function(source, args)
    local days = tonumber(args[1]) or 30
    DoorLockUtils.CleanOldLogs(days)
    TriggerClientEvent('QBCore:Notify', source, string.format('Logs de plus de %d jours supprimés', days), 'success')
end, 'god')

-- Commande pour recharger la config
QBCore.Commands.Add('reloaddoors', 'Recharger la configuration des portes', {}, false, function(source, args)
    TriggerClientEvent('qb-doorlock:client:reloadConfig', -1)
    TriggerClientEvent('QBCore:Notify', source, 'Configuration des portes rechargée', 'success')
end, 'admin')

-- Commande pour les statistiques
QBCore.Commands.Add('doorstats', 'Statistiques du système de portes', {}, false, function(source, args)
    local totalDoors = 0
    local lockedDoors = 0
    
    for doorId, _ in pairs(Config.Doors) do
        totalDoors = totalDoors + 1
        if doorStates[doorId] then
            lockedDoors = lockedDoors + 1
        end
    end
    
    local messages = {
        {color = {100, 200, 100}, args = {"STATS", "=== Statistiques QB-Doorlock ==="}},
        {color = {200, 200, 200}, args = {"STATS", string.format("Portes totales: %d", totalDoors)}},
        {color = {200, 200, 200}, args = {"STATS", string.format("Portes verrouillées: %d", lockedDoors)}},
        {color = {200, 200, 200}, args = {"STATS", string.format("Portes ouvertes: %d", totalDoors - lockedDoors)}}
    }
    
    for _, message in ipairs(messages) do
        TriggerClientEvent('chat:addMessage', source, message)
    end
end, 'admin')

-- Commande pour déverrouillage d'urgence
QBCore.Commands.Add('emergencyunlock', 'Déverrouiller toutes les portes d\'un job (urgence)', {
    {name = 'job', help = 'Nom du job (police, ambulance, etc.)'}
}, false, function(source, args)
    local job = args[1]
    
    if job then
        local unlockedDoors = 0
        
        for doorId, door in pairs(Config.Doors) do
            if door.authorizedJobs then
                for _, authorizedJob in ipairs(door.authorizedJobs) do
                    if authorizedJob == job then
                        doorStates[doorId] = false
                        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, false)
                        DoorLockUtils.SaveDoorState(doorId, false, 'EMERGENCY')
                        unlockedDoors = unlockedDoors + 1
                        break
                    end
                end
            end
        end
        
        TriggerClientEvent('QBCore:Notify', source, string.format('%d portes déverrouillées pour le job %s', unlockedDoors, job), 'success')
        TriggerClientEvent('QBCore:Notify', -1, string.format('URGENCE: Toutes les portes %s déverrouillées', job), 'error')
        
        -- Log de sécurité
        MySQL.Async.execute('INSERT INTO doorlock_security_logs (door_id, citizenid, event_type, details, severity) VALUES (?, ?, ?, ?, ?)', {
            'MULTIPLE', source, 'emergency', string.format('Déverrouillage d\'urgence pour job: %s', job), 'critical'
        })
    end
end, 'god')

-- Commande pour voir la version
QBCore.Commands.Add('doorlockversion', 'Vérifier la version QB-Doorlock', {}, false, function(source, args)
    local version = Config.Version or "1.0.0"
    
    local info = {
        {color = {100, 200, 100}, args = {"VERSION", "=== QB-Doorlock Version Info ==="}},
        {color = {200, 200, 200}, args = {"VERSION", "Version: " .. version}},
        {color = {200, 200, 200}, args = {"VERSION", "Author: QB-Doorlock Team"}},
        {color = {200, 200, 200}, args = {"VERSION", "Compatible: PS-Housing v1.x et v2.0.x"}},
        {color = {200, 200, 200}, args = {"VERSION", "Status: Opérationnel"}}
    }
    
    for _, message in ipairs(info) do
        TriggerClientEvent('chat:addMessage', source, message)
    end
end, 'admin')

-- ================================
-- THREADS ET ÉVÉNEMENTS PROGRAMMÉS
-- ================================

-- Nettoyer les logs automatiquement chaque semaine
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(7 * 24 * 60 * 60 * 1000) -- 7 jours
        DoorLockUtils.CleanOldLogs(30)
        print('[QB-DOORLOCK] Nettoyage automatique des logs effectué')
    end
end)

-- Gérer les horaires automatiques
Citizen.CreateThread(function()
    while true do
        local currentHour = tonumber(os.date("%H"))
        
        for doorId, door in pairs(Config.Doors) do
            if door.schedule then
                local shouldBeOpen = DoorLockUtils.IsWithinSchedule(door)
                local currentState = doorStates[doorId]
                
                -- Si la porte devrait être ouverte mais est fermée, ou vice versa
                if (shouldBeOpen and currentState) or (not shouldBeOpen and not currentState) then
                    doorStates[doorId] = not shouldBeOpen
                    TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, not shouldBeOpen)
                    DoorLockUtils.SaveDoorState(doorId, not shouldBeOpen, 'SYSTEM')
                    
                    print(string.format('[QB-DOORLOCK] Horaire automatique: Porte %s %s', 
                        doorId, 
                        shouldBeOpen and 'ouverte' or 'fermée'
                    ))
                end
            end
        end
        
        Citizen.Wait(60000) -- Vérifier chaque minute
    end
end)

-- ================================
-- EXPORTS
-- ================================

-- Export pour obtenir l'état d'une porte
exports('GetDoorState', function(doorId)
    return doorStates[doorId]
end)

-- Export pour définir l'état d'une porte
exports('SetDoorState', function(doorId, state)
    if Config.Doors[doorId] then
        doorStates[doorId] = state
        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, state)
        DoorLockUtils.SaveDoorState(doorId, state, 'SCRIPT')
        return true
    end
    return false
end)

-- Export pour vérifier l'autorisation
exports('IsAuthorized', function(source, doorId)
    return IsAuthorized(source, doorId)
end)

-- Export pour logger une activité
exports('LogActivity', function(doorId, citizenid, action, job, grade, method)
    DoorLockUtils.LogActivity(doorId, citizenid, action, job, grade, method)
end)

-- Export compatible ox_doorlock (pour compatibilité)
exports('editDoorlock', function(doorId, data)
    if not doorId or not data then return false end
    
    if data.locked ~= nil then
        doorStates[doorId] = data.locked
        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, data.locked)
        DoorLockUtils.SaveDoorState(doorId, data.locked, 'EXTERNAL')
        return true
    end
    
    return false
end)

-- ================================
-- INITIALISATION
-- ================================

-- Initialisation au démarrage du serveur
Citizen.CreateThread(function()
    -- Attendre que MySQL soit prêt
    while not MySQL do
        Citizen.Wait(100)
    end
    
    -- Charger les états des portes
    DoorLockUtils.LoadDoorStates()
    
    -- Attendre un peu puis initialiser les états par défaut
    Citizen.Wait(2000)
    
    -- Initialiser les portes qui n'existent pas en base
    for doorId, door in pairs(Config.Doors) do
        if doorStates[doorId] == nil then
            doorStates[doorId] = door.locked or false
            DoorLockUtils.SaveDoorState(doorId, doorStates[doorId], 'SYSTEM')
        end
    end
    
    print(string.format('[QB-DOORLOCK] Serveur initialisé - %d portes configurées', #Config.Doors))
end)

-- Export des utilitaires pour d'autres ressources
_G.DoorLockUtils = DoorLockUtils

print('[QB-DOORLOCK] Module serveur principal chargé')
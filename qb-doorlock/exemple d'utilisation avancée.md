-- ================================
-- EXEMPLES D'UTILISATION AVANCÉE
-- ================================

-- 1. INTÉGRATION AVEC UN SYSTÈME DE MAISONS
RegisterNetEvent('qb-doorlock:house:updateKey')
AddEventHandler('qb-doorlock:house:updateKey', function(houseId, citizenid)
    -- Donner la clé de maison à un joueur
    local Player = QBCore.Functions.GetPlayer(citizenid)
    if Player then
        Player.Functions.AddItem('house_key_' .. houseId, 1)
        TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items['house_key_' .. houseId], "add")
    end
    
    -- Mettre à jour la porte pour ce joueur
    local doorId = 'house_' .. houseId
    TriggerClientEvent('qb-doorlock:client:updateHouseAccess', -1, doorId, citizenid)
end)

-- 2. SYSTÈME DE BRAQUAGE DE BANQUE
RegisterNetEvent('qb-heists:vault:hack')
AddEventHandler('qb-heists:vault:hack', function(bankId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Vérifier si le joueur a les outils nécessaires
    local hasLaptop = Player.Functions.GetItemByName('laptop_hack')
    local hasCard = Player.Functions.GetItemByName('bank_card')
    
    if hasLaptop and hasCard then
        -- Démarrer le mini-jeu de hack
        TriggerClientEvent('qb-heists:client:startHack', src, bankId)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Équipement insuffisant pour le hack', 'error')
    end
end)

RegisterNetEvent('qb-heists:vault:success')
AddEventHandler('qb-heists:vault:success', function(bankId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Déverrouiller temporairement le coffre
    local doorId = 'fleeca_vault_' .. bankId
    TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, false)
    
    -- Log de sécurité
    TriggerEvent('qb-doorlock:server:emergencyLog', doorId, Player.PlayerData.citizenid, 'VAULT_BREACHED')
    
    -- Réverrouiller après 5 minutes
    SetTimeout(300000, function()
        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
    end)
end)

-- 3. SYSTÈME D'URGENCE MÉDICAL
RegisterNetEvent('qb-ambulancejob:emergency:access')
AddEventHandler('qb-ambulancejob:emergency:access', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.name == 'ambulance' then
        -- Déverrouiller toutes les portes d'hôpital en urgence
        local emergencyDoors = {'pillbox_main', 'pillbox_surgery', 'pillbox_trauma'}
        
        for _, doorId in ipairs(emergencyDoors) do
            TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, false)
        end
        
        TriggerClientEvent('QBCore:Notify', src, 'Mode urgence activé - Toutes les portes ouvertes', 'success')
        TriggerClientEvent('QBCore:Notify', -1, 'URGENCE MÉDICALE - Accès libre hôpital', 'primary')
        
        -- Réverrouiller après 10 minutes
        SetTimeout(600000, function()
            for _, doorId in ipairs(emergencyDoors) do
                TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
            end
            TriggerClientEvent('QBCore:Notify', -1, 'Fin de l\'urgence - Accès normal rétabli', 'primary')
        end)
    end
end)

-- 4. INTÉGRATION AVEC SYSTÈME DE GANGS
RegisterNetEvent('qb-gangs:territory:control')
AddEventHandler('qb-gangs:territory:control', function(territoryId, gangName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Si un gang prend le contrôle d'un territoire, ils obtiennent l'accès aux portes
    local territoryDoors = Config.TerritoryDoors[territoryId]
    
    if territoryDoors then
        for _, doorId in ipairs(territoryDoors) do
            -- Donner accès temporaire au gang
            Config.Doors[doorId].authorizedGangs = {gangName}
            TriggerClientEvent('qb-doorlock:client:updateDoorConfig', -1, doorId, Config.Doors[doorId])
        end
        
        -- Log l'événement
        MySQL.Async.execute('INSERT INTO doorlock_logs (door_id, citizenid, action, job, grade) VALUES (?, ?, ?, ?, ?)', {
            'TERRITORY_' .. territoryId, 
            Player.PlayerData.citizenid, 
            'gang_takeover', 
            gangName, 
            0
        })
    end
end)

-- 5. SYSTÈME DE MAINTENANCE PROGRAMMÉE
RegisterNetEvent('qb-doorlock:maintenance:schedule')
AddEventHandler('qb-doorlock:maintenance:schedule', function(doorId, startTime, endTime, reason)
    local src = source
    
    -- Programmer la maintenance
    local maintenanceData = {
        doorId = doorId,
        startTime = startTime,
        endTime = endTime,
        reason = reason,
        scheduledBy = src
    }
    
    -- Sauvegarder en base
    MySQL.Async.execute('INSERT INTO doorlock_maintenance (door_id, start_time, end_time, reason, scheduled_by) VALUES (?, ?, ?, ?, ?)', {
        doorId, startTime, endTime, reason, src
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'Maintenance programmée pour ' .. doorId, 'success')
end)

-- 6. SYSTÈME DE PERMISSIONS TEMPORAIRES
local temporaryAccess = {}

RegisterNetEvent('qb-doorlock:temp:grantAccess')
AddEventHandler('qb-doorlock:temp:grantAccess', function(targetId, doorId, duration)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if not Target then return end
    
    -- Vérifier si le joueur source a les permissions d'accorder l'accès
    local door = Config.Doors[doorId]
    if not door then return end
    
    local hasPermission = false
    if door.authorizedJobs then
        for _, job in ipairs(door.authorizedJobs) do
            if Player.PlayerData.job.name == job and Player.PlayerData.job.grade.level >= 3 then
                hasPermission = true
                break
            end
        end
    end
    
    if hasPermission then
        -- Accorder l'accès temporaire
        local accessKey = targetId .. '_' .. doorId
        temporaryAccess[accessKey] = {
            granted = os.time(),
            expires = os.time() + duration,
            grantedBy = src
        }
        
        TriggerClientEvent('QBCore:Notify', targetId, string.format('Accès temporaire accordé pour %s (%d min)', doorId, duration/60), 'success')
        TriggerClientEvent('QBCore:Notify', src, string.format('Accès accordé à %s pour %s', Target.PlayerData.charinfo.firstname, doorId), 'success')
        
        -- Retirer l'accès après expiration
        SetTimeout(duration * 1000, function()
            temporaryAccess[accessKey] = nil
            if Target then
                TriggerClientEvent('QBCore:Notify', targetId, 'Accès temporaire expiré pour ' .. doorId, 'error')
            end
        end)
    end
end)

-- Fonction pour vérifier l'accès temporaire
function HasTemporaryAccess(source, doorId)
    local accessKey = source .. '_' .. doorId
    local access = temporaryAccess[accessKey]
    
    if access and os.time() < access.expires then
        return true
    end
    
    return false
end

-- 7. INTÉGRATION AVEC UN SYSTÈME DE LEVEL/XP
RegisterNetEvent('qb-doorlock:skill:levelup')
AddEventHandler('qb-doorlock:skill:levelup', function(skillName, level)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Débloquer des portes en fonction du niveau de compétence
    if skillName == 'lockpicking' then
        local unlockedDoors = {}
        
        if level >= 50 then
            table.insert(unlockedDoors, 'basic_locks')
        end
        if level >= 75 then
            table.insert(unlockedDoors, 'advanced_locks')
        end
        if level >= 100 then
            table.insert(unlockedDoors, 'master_locks')
        end
        
        -- Mettre à jour les permissions du joueur
        TriggerClientEvent('qb-doorlock:client:updateSkillAccess', src, unlockedDoors)
    end
end)

-- 8. SYSTÈME D'ALARME INTELLIGENT
local alarmCooldowns = {}

RegisterNetEvent('qb-doorlock:alarm:trigger')
AddEventHandler('qb-doorlock:alarm:trigger', function(doorId, alarmType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Vérifier le cooldown
    if alarmCooldowns[doorId] and (os.time() - alarmCooldowns[doorId]) < 300 then
        return -- 5 minutes de cooldown
    end
    
    alarmCooldowns[doorId] = os.time()
    
    -- Déclencher l'alarme
    local door = Config.Doors[doorId]
    if door and door.hasAlarm then
        -- Alerter la police
        if door.authorizedJobs then
            for _, job in ipairs(door.authorizedJobs) do
                local players = QBCore.Functions.GetQBPlayers()
                for _, player in pairs(players) do
                    if player.PlayerData.job.name == job then
                        TriggerClientEvent('qb-doorlock:client:alarmAlert', player.PlayerData.source, {
                            doorId = doorId,
                            location = door.objCoords,
                            alarmType = alarmType,
                            time = os.time()
                        })
                    end
                end
            end
        end
        
        -- Verrouiller automatiquement si déverrouillée
        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
        
        -- Log de sécurité
        MySQL.Async.execute('INSERT INTO doorlock_security_logs (door_id, citizenid, event_type, coordinates, timestamp) VALUES (?, ?, ?, ?, ?)', {
            doorId, 
            Player.PlayerData.citizenid, 
            alarmType,
            json.encode(door.objCoords),
            os.time()
        })
    end
end)

-- 9. COMMANDES UTILITAIRES POUR STAFF
QBCore.Commands.Add('grantdooraccess', 'Accorder un accès temporaire à une porte', {
    {name = 'id', help = 'ID du joueur'},
    {name = 'doorId', help = 'ID de la porte'},
    {name = 'duration', help = 'Durée en minutes'}
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local doorId = args[2]
    local duration = tonumber(args[3]) * 60 -- Convertir en secondes
    
    if targetId and doorId and duration then
        TriggerEvent('qb-doorlock:temp:grantAccess', source, targetId, doorId, duration)
    end
end, 'admin')

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
                        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, false)
                        unlockedDoors = unlockedDoors + 1
                        break
                    end
                end
            end
        end
        
        TriggerClientEvent('QBCore:Notify', source, string.format('%d portes déverrouillées pour le job %s', unlockedDoors, job), 'success')
        TriggerClientEvent('QBCore:Notify', -1, string.format('URGENCE: Toutes les portes %s déverrouillées', job), 'error')
    end
end, 'god')

-- 10. INTÉGRATION AVEC UN SYSTÈME MÉTÉO
RegisterNetEvent('qb-weathersync:client:SyncWeather')
AddEventHandler('qb-weathersync:client:SyncWeather', function(newWeather)
    -- Certaines portes se verrouillent automatiquement en cas de tempête
    if newWeather == 'THUNDER' or newWeather == 'RAIN' then
        for doorId, door in pairs(Config.Doors) do
            if door.weatherLock then
                TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
            end
        end
        
        TriggerClientEvent('QBCore:Notify', -1, 'Verrouillage automatique dû aux conditions météo', 'primary')
    end
end)

-- ================================
-- CONFIGURATION ÉTENDUE
-- ================================

-- Ajout à la config principale
Config.TerritoryDoors = {
    ['south_los_santos'] = {'gang_hideout_1', 'gang_warehouse_1'},
    ['downtown'] = {'gang_hideout_2', 'gang_warehouse_2'},
    ['sandy_shores'] = {'gang_hideout_3', 'gang_warehouse_3'}
}

-- Portes spéciales avec fonctionnalités avancées
Config.SpecialDoors = {
    ['bank_vault_main'] = {
        objName = 'hei_prop_heist_sec_door',
        objCoords = vector3(255.0, -283.0, 54.16),
        textCoords = vector3(255.0, -284.0, 55.16),
        authorizedJobs = {'police'},
        locked = true,
        distance = 3.0,
        hasAlarm = true,
        requiresMultipleKeys = true, -- Nécessite plusieurs clés
        keyHolders = 2, -- Nombre de personnes requises
        weatherLock = true, -- Se verrouille par mauvais temps
        maintenanceMode = false,
        requiredItems = {
            {item = 'vault_key_1', remove = false},
            {item = 'vault_key_2', remove = false},
            {item = 'security_override', remove = true}
        },
        schedule = {
            openHour = 9,
            closeHour = 17,
            weekendsOnly = false
        },
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:multiKeyAccess",
                icon = "fas fa-vault",
                label = "Accès Coffre-fort (2 clés requises)",
                job = {'police'}
            }
        },
        notifications = {
            success = "Coffre-fort déverrouillé",
            fail = "Erreur de sécurité",
            multiKeyWaiting = "En attente de la seconde clé...",
            multiKeySuccess = "Accès autorisé - Double authentification"
        }
    }
}

-- ================================
-- FONCTIONS AVANCÉES CLIENT
-- ================================

-- Event pour l'accès multi-clés
RegisterNetEvent('qb-doorlock:client:multiKeyAccess')
AddEventHandler('qb-doorlock:client:multiKeyAccess', function(data)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local doorId = 'bank_vault_main' -- Exemple
    local door = Config.SpecialDoors[doorId]
    
    if door and door.requiresMultipleKeys then
        TriggerServerEvent('qb-doorlock:server:initiateMultiKey', doorId)
    end
end)

-- Système de notification d'alarme
RegisterNetEvent('qb-doorlock:client:alarmAlert')
AddEventHandler('qb-doorlock:client:alarmAlert', function(alarmData)
    -- Créer un blip temporaire
    local blip = AddBlipForCoord(alarmData.location.x, alarmData.location.y, alarmData.location.z)
    SetBlipSprite(blip, 161) -- Icône alarme
    SetBlipColour(blip, 1) -- Rouge
    SetBlipScale(blip, 1.2)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🚨 ALARME: " .. alarmData.doorId)
    EndTextCommandSetBlipName(blip)
    
    -- Notification avec son
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
    QBCore.Functions.Notify("🚨 ALARME DÉCLENCHÉE: " .. alarmData.doorId, "error", 10000)
    
    -- Retirer le blip après 10 minutes
    SetTimeout(600000, function()
        RemoveBlip(blip)
    end)
end)

-- Export pour autres ressources
exports('HasTemporaryAccess', HasTemporaryAccess)
exports('TriggerAlarm', function(doorId, alarmType)
    TriggerEvent('qb-doorlock:alarm:trigger', doorId, alarmType)
end)
exports('GrantTemporaryAccess', function(source, targetId, doorId, duration)
    TriggerEvent('qb-doorlock:temp:grantAccess', source, targetId, doorId, duration)
end)
-- ================================
-- CLIENT PS-HOUSING POUR QB-DOORLOCK
-- client/pshousing_integration.lua
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables pour les maisons
local houseDoors = {}
local nearbyHouses = {}

-- ================================
-- FONCTIONS UTILITAIRES MAISONS
-- ================================

local function GetHouseIdFromDoorId(doorId)
    return doorId and doorId:gsub('^house_', '') or nil
end

local function IsHouseDoor(doorId)
    return doorId and doorId:match('^house_') ~= nil
end

-- Fonction pour vérifier l'accès à une maison
local function HasHouseAccess(doorId)
    local houseId = GetHouseIdFromDoorId(doorId)
    if not houseId then return false end
    
    -- Vérifier via callback serveur
    local hasAccess = false
    QBCore.Functions.TriggerCallback('qb-doorlock:hasHouseAccess', function(result)
        hasAccess = result
    end, houseId)
    
    -- Attendre la réponse (synchrone pour cette vérification)
    local timeout = 0
    while hasAccess == false and timeout < 100 do
        timeout = timeout + 1
        Citizen.Wait(10)
    end
    
    return hasAccess
end

-- Interface spéciale pour les maisons
local function ShowHouseUI(doorId, doorConfig)
    local door = doors[doorId]
    if not door then return end
    
    local houseId = doorConfig.houseId
    local lockState = door.locked and "VERROUILLÉE" or "OUVERTE"
    local color = door.locked and "~r~" or "~g~"
    local icon = door.locked and "🏠🔒" or "🏠🔓"
    
    -- Affichage 3D pour maison
    if Config.Use3DText then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(color .. icon .. " MAISON " .. lockState)
        SetDrawOrigin(doorConfig.textCoords.x, doorConfig.textCoords.y, doorConfig.textCoords.z, 0)
        DrawText(0.0, 0.0)
        ClearDrawOrigin()
    end
    
    -- Informations détaillées pour les maisons
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - doorConfig.textCoords)
    
    if distance < 2.0 then
        local infoText = ""
        
        -- Vérifier l'accès via ps-housing
        QBCore.Functions.TriggerCallback('qb-doorlock:hasHouseAccess', function(hasAccess)
            if hasAccess then
                infoText = "~g~[E]~w~ " .. (door.locked and "Déverrouiller" or "Verrouiller") .. " la maison"
                infoText = infoText .. "\n~y~🏠 Maison ID: ~w~" .. houseId
                
                -- Vérifier si le joueur a la clé physique
                local keyItem = Config.PSHousing.KeyItemPrefix .. houseId
                local hasKey = exports['ps-inventory']:HasItem(keyItem, 1)
                if hasKey then
                    infoText = infoText .. "\n~g~✓~w~ Clé de maison"
                else
                    infoText = infoText .. "\n~b~ⓘ~w~ Accès temporaire"
                end
            else
                infoText = "~r~🔒 Maison verrouillée~w~"
                infoText = infoText .. "\n~r~Clé requise pour accéder"
            end
            
            QBCore.Functions.DrawText(infoText, 'left')
        end, houseId)
        
        currentDoorId = doorId
        isNearDoor = true
    end
end

-- Override de la fonction principale pour les maisons
local originalShowDoorUI = ShowDoorUI
function ShowDoorUI(doorId, doorConfig)
    if doorConfig.isHouseDoor then
        ShowHouseUI(doorId, doorConfig)
    else
        originalShowDoorUI(doorId, doorConfig)
    end
end

-- ================================
-- EVENTS PS-HOUSING CLIENT
-- ================================

-- Event pour ajouter une porte de maison dynamiquement
RegisterNetEvent('qb-doorlock:client:addHouseDoor')
AddEventHandler('qb-doorlock:client:addHouseDoor', function(doorId, doorConfig)
    -- Trouver l'objet porte
    local door = GetClosestObjectOfType(
        doorConfig.objCoords.x, 
        doorConfig.objCoords.y, 
        doorConfig.objCoords.z, 
        2.0, 
        GetHashKey(doorConfig.objName), 
        false, false, false
    )
    
    if door ~= 0 then
        doors[doorId] = {
            object = door,
            locked = doorConfig.locked
        }
        
        -- Définir l'état initial
        FreezeEntityPosition(door, doorConfig.locked)
        
        -- Ajouter qb-target
        exports['qb-target']:AddTargetEntity(door, {
            options = doorConfig.targetOptions,
            distance = doorConfig.distance
        })
        
        -- Ajouter à la config locale
        Config.Doors[doorId] = doorConfig
        
        print(string.format('[QB-DOORLOCK] Porte de maison ajoutée: %s', doorId))
    else
        print(string.format('[QB-DOORLOCK] Impossible de trouver l\'objet porte pour: %s', doorId))
    end
end)

-- Event pour supprimer une porte de maison
RegisterNetEvent('qb-doorlock:client:removeHouseDoor')
AddEventHandler('qb-doorlock:client:removeHouseDoor', function(doorId)
    local door = doors[doorId]
    if door then
        -- Retirer qb-target
        exports['qb-target']:RemoveTargetEntity(door.object)
        
        -- Nettoyer
        doors[doorId] = nil
        Config.Doors[doorId] = nil
        
        print(string.format('[QB-DOORLOCK] Porte de maison supprimée: %s', doorId))
    end
end)

-- Event pour l'interaction avec une maison
RegisterNetEvent('qb-doorlock:client:houseInteraction')
AddEventHandler('qb-doorlock:client:houseInteraction', function(data)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local doorId = nil
    local minDistance = math.huge
    
    -- Trouver la porte de maison la plus proche
    for id, doorConfig in pairs(Config.Doors) do
        if doorConfig.isHouseDoor then
            local distance = #(playerCoords - doorConfig.objCoords)
            if distance < minDistance and distance < doorConfig.distance then
                minDistance = distance
                doorId = id
            end
        end
    end
    
    if doorId then
        -- Animation spéciale pour les maisons
        local ped = PlayerPedId()
        RequestAnimDict("anim@heists@keycard@")
        while not HasAnimDictLoaded("anim@heists@keycard@") do
            Citizen.Wait(1)
        end
        TaskPlayAnim(ped, "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 48, 0, 0, 0, 0)
        
        -- Envoyer au serveur
        TriggerServerEvent('qb-doorlock:server:houseInteraction', doorId)
    end
end)

-- ================================
-- INTÉGRATION AVEC PS-HOUSING UI
-- ================================

-- Event quand le joueur ouvre le menu de gestion de maison
RegisterNetEvent('ps-housing:client:openHouseManagement')
AddEventHandler('ps-housing:client:openHouseManagement', function(houseId)
    -- Ajouter les options de porte dans le menu ps-housing
    local doorId = 'house_' .. houseId
    local door = doors[doorId]
    
    if door then
        local doorState = door.locked and "Verrouillée" or "Déverrouillée"
        
        -- Ajouter au menu ps-housing (si supporté)
        TriggerEvent('ps-housing:client:addMenuOption', {
            label = "🔐 Porte: " .. doorState,
            action = function()
                TriggerServerEvent('qb-doorlock:server:houseInteraction', doorId)
            end
        })
    end
end)

-- Event pour notifier le changement d'état d'une porte de maison
RegisterNetEvent('qb-doorlock:client:houseStateChanged')
AddEventHandler('qb-doorlock:client:houseStateChanged', function(houseId, locked)
    local doorId = 'house_' .. houseId
    local door = doors[doorId]
    
    if door then
        door.locked = locked
        FreezeEntityPosition(door.object, locked)
        
        -- Son spécial pour les maisons
        local soundName = locked and "Door_Close" or "Door_Open"
        PlaySoundFromEntity(-1, soundName, PlayerPedId(), "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0, 0)
        
        -- Effet visuel
        if locked then
            SetLightBrightnessFactor(1.2) -- Lumière plus forte quand verrouillé
        else
            SetLightBrightnessFactor(1.0)
        end
        
        -- Notification spéciale
        local stateText = locked and "verrouillée" or "déverrouillée"
        QBCore.Functions.Notify("🏠 Maison " .. stateText, "success")
    end
end)

-- ================================
-- SYSTÈME DE PROXIMITÉ POUR MAISONS
-- ================================

-- Thread pour détecter les maisons proches
Citizen.CreateThread(function()
    while true do
        local wait = 2000
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        -- Chercher les maisons proches
        nearbyHouses = {}
        
        for doorId, doorConfig in pairs(Config.Doors) do
            if doorConfig.isHouseDoor then
                local distance = #(playerCoords - doorConfig.objCoords)
                if distance < 50.0 then -- 50m de rayon
                    wait = 500
                    table.insert(nearbyHouses, {
                        doorId = doorId,
                        houseId = doorConfig.houseId,
                        distance = distance,
                        locked = doors[doorId] and doors[doorId].locked
                    })
                end
            end
        end
        
        Citizen.Wait(wait)
    end
end)

-- ================================
-- COMMANDES POUR DEBUG MAISONS
-- ================================

-- Commande pour lister les maisons proches
RegisterCommand('nearbyhouses', function()
    if #nearbyHouses == 0 then
        QBCore.Functions.Notify("Aucune maison à proximité", "error")
        return
    end
    
    for _, house in ipairs(nearbyHouses) do
        local stateText = house.locked and "🔒" or "🔓"
        local message = string.format("%s Maison %s (%.1fm) - %s", 
            stateText, 
            house.houseId, 
            house.distance,
            house.locked and "Verrouillée" or "Ouverte"
        )
        TriggerEvent('chat:addMessage', {
            color = {100, 200, 100},
            args = {"MAISONS", message}
        })
    end
end, false)

-- Commande pour créer une porte de maison à la position actuelle
RegisterCommand('createhousedoor', function(source, args)
    if not args[1] then
        QBCore.Functions.Notify("Usage: /createhousedoor [houseId]", "error")
        return
    end
    
    local houseId = args[1]
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    TriggerServerEvent('qb-doorlock:server:createHouseDoorAtPosition', houseId, playerCoords)
end, false)

-- ================================
-- EXPORTS POUR PS-HOUSING
-- ================================

-- Export pour obtenir l'état d'une porte de maison
exports('getHouseDoorState', function(houseId)
    local doorId = 'house_' .. houseId
    local door = doors[doorId]
    return door and door.locked or nil
end)

-- Export pour vérifier si une maison a une porte configurée
exports('hasHouseDoor', function(houseId)
    local doorId = 'house_' .. houseId
    return doors[doorId] ~= nil
end)

-- Export pour obtenir les maisons proches
exports('getNearbyHouses', function()
    return nearbyHouses
end)

-- Export pour forcer la création d'une porte de maison
exports('forceCreateHouseDoor', function(houseId, doorData)
    local doorId = 'house_' .. houseId
    TriggerEvent('qb-doorlock:client:addHouseDoor', doorId, doorData)
end)

-- ================================
-- FICHIER DE REMPLACEMENT POUR PS-HOUSING
-- ps-housing/server/main.lua (SECTION À AJOUTER)
-- ================================

--[[
-- Ajouter cette section dans ps-housing/server/main.lua

-- QB-Doorlock Integration
if GetResourceState('qb-doorlock') == 'started' then
    -- Fonction appelée quand une maison est créée
    local function CreateHouseDoorlock(houseId, houseData)
        if houseData.door and houseData.door.coords then
            exports['qb-doorlock']:createHouseDoor(houseId, {
                model = houseData.door.model or 'v_ilev_fh_frontdoor',
                coords = houseData.door.coords
            })
        end
    end
    
    -- Fonction appelée quand une maison est supprimée
    local function RemoveHouseDoorlock(houseId)
        exports['qb-doorlock']:removeHouseDoor(houseId)
    end
    
    -- Hook dans les événements ps-housing existants
    local originalBuyHouse = BuyHouse
    function BuyHouse(source, houseId)
        local result = originalBuyHouse(source, houseId)
        if result then
            local houseData = GetHouse(houseId)
            CreateHouseDoorlock(houseId, houseData)
        end
        return result
    end
    
    local originalSellHouse = SellHouse  
    function SellHouse(source, houseId)
        local result = originalSellHouse(source, houseId)
        if result then
            RemoveHouseDoorlock(houseId)
        end
        return result
    end
    
    -- Charger les portes existantes au démarrage
    Citizen.CreateThread(function()
        Wait(5000) -- Attendre que qb-doorlock soit complètement chargé
        
        local houses = GetAllHouses()
        for houseId, houseData in pairs(houses) do
            if houseData.owner then
                CreateHouseDoorlock(houseId, houseData)
            end
        end
        
        print('[PS-HOUSING] Intégration QB-Doorlock activée')
    end)
end
--]]

-- ================================
-- CONFIGURATION ÉTENDUE POUR MAISONS
-- ================================

-- Ajouter cette section à config.lua
Config.HouseIntegration = {
    -- Types de portes par défaut pour différents types de maisons
    DefaultDoors = {
        ['apartment'] = {
            model = 'v_ilev_genericdoor02',
            offset = vector3(0, 0, 0)
        },
        ['house'] = {
            model = 'v_ilev_fh_frontdoor', 
            offset = vector3(0, 0, 0)
        },
        ['mansion'] = {
            model = 'v_ilev_lest_bigdoor',
            offset = vector3(0, 0, 0)
        },
        ['garage'] = {
            model = 'prop_com_gar_door_01',
            offset = vector3(0, 0, 0)
        }
    },
    
    -- Configuration des clés de maison
    HouseKeys = {
        -- Préfixe des items de clés
        keyPrefix = 'house_key_',
        -- Durée par défaut des clés temporaires (en secondes)
        defaultTempDuration = 3600,
        -- Permettre aux agents immobiliers d'accéder
        realtorAccess = true,
        -- Jobs qui peuvent créer des clés de maison
        keyMakers = {'realestate', 'mechanic'},
    },
    
    -- Notifications spéciales pour les maisons
    Notifications = {
        houseUnlocked = "🏠 Maison déverrouillée",
        houseLocked = "🏠 Maison verrouillée", 
        keyReceived = "🔑 Vous avez reçu une clé de maison",
        keyRemoved = "🔑 Votre clé de maison a été retirée",
        accessDenied = "🚫 Vous n'avez pas la clé de cette maison",
        tempKeyExpired = "⏰ Votre clé temporaire a expiré"
    }
}

-- Items spéciaux pour les maisons (à ajouter dans qb-core/shared/items.lua)
local HouseItems = {
    -- Clé générique de maison (template)
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
        ['description'] = 'Clé d\'une maison privée'
    },
    
    -- Kit de duplication de clés
    ['key_duplication_kit'] = {
        ['name'] = 'key_duplication_kit',
        ['label'] = 'Kit de Duplication',
        ['weight'] = 500,
        ['type'] = 'item', 
        ['image'] = 'key_duplication_kit.png',
        ['unique'] = false,
        ['useable'] = true,
        ['shouldClose'] = true,
        ['combinable'] = nil,
        ['description'] = 'Permet de dupliquer des clés de maison'
    },
    
    -- Passe-partout (pour agents immobiliers)
    ['master_key'] = {
        ['name'] = 'master_key',
        ['label'] = 'Passe-Partout',
        ['weight'] = 100,
        ['type'] = 'item',
        ['image'] = 'master_key.png', 
        ['unique'] = true,
        ['useable'] = true,
        ['shouldClose'] = false,
        ['combinable'] = nil,
        ['description'] = 'Clé universelle pour agent immobilier'
    }
}

-- ================================
-- SYSTÈME DE DUPLICATION DE CLÉS
-- ================================

RegisterNetEvent('qb-doorlock:client:duplicateKey')
AddEventHandler('qb-doorlock:client:duplicateKey', function(data)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Vérifier si le joueur a le kit de duplication
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasKit)
        if not hasKit then
            QBCore.Functions.Notify("Vous avez besoin d'un kit de duplication", "error")
            return
        end
        
        -- Animation de duplication
        RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
        while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do
            Citizen.Wait(1)
        end
        
        TaskPlayAnim(playerPed, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, 0, 0, 0)
        
        -- Barre de progression
        QBCore.Functions.Progressbar("duplicate_key", "Duplication de la clé...", 10000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Success
            ClearPedTasks(playerPed)
            TriggerServerEvent('qb-doorlock:server:duplicateKey', data.houseId)
        end, function() -- Cancel
            ClearPedTasks(playerPed)
            QBCore.Functions.Notify("Duplication annulée", "error")
        end)
        
    end, 'key_duplication_kit')
end)

-- Event serveur pour la duplication
RegisterNetEvent('qb-doorlock:server:duplicateKey')
AddEventHandler('qb-doorlock:server:duplicateKey', function(houseId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Vérifier si le joueur a accès à la maison
    if not HasHouseAccess(src, houseId) then
        TriggerClientEvent('QBCore:Notify', src, 'Vous n\'avez pas accès à cette maison', 'error')
        return
    end
    
    -- Vérifier le kit
    local hasKit = Player.Functions.GetItemByName('key_duplication_kit')
    if not hasKit then
        TriggerClientEvent('QBCore:Notify', src, 'Kit de duplication requis', 'error')
        return
    end
    
    -- Consommer le kit (chance d'échec)
    if math.random(1, 100) <= 10 then -- 10% de chance d'échec
        Player.Functions.RemoveItem('key_duplication_kit', 1)
        TriggerClientEvent('QBCore:Notify', src, 'Duplication échouée - Kit cassé', 'error')
        return
    end
    
    -- Créer la clé dupliquée
    local keyItem = Config.PSHousing.KeyItemPrefix .. houseId
    Player.Functions.AddItem(keyItem, 1, false, {
        house = houseId,
        duplicated = true,
        created = os.time()
    })
    
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[keyItem], "add")
    TriggerClientEvent('QBCore:Notify', src, 'Clé dupliquée avec succès', 'success')
    
    -- Log de sécurité
    MySQL.Async.execute('INSERT INTO doorlock_logs (door_id, citizenid, action, job, grade) VALUES (?, ?, ?, ?, ?)', {
        'house_' .. houseId, 
        Player.PlayerData.citizenid, 
        'key_duplicated', 
        Player.PlayerData.job.name, 
        Player.PlayerData.job.grade.level
    })
end)

-- ================================
-- SYSTÈME DE MAINTENANCE POUR MAISONS
-- ================================

-- Event pour signaler un problème de porte
RegisterNetEvent('qb-doorlock:client:reportHouseDoorIssue')
AddEventHandler('qb-doorlock:client:reportHouseDoorIssue', function(houseId)
    local issue = {
        type = 'door_malfunction',
        houseId = houseId,
        reportedBy = PlayerPedId(),
        location = GetEntityCoords(PlayerPedId()),
        timestamp = os.time()
    }
    
    TriggerServerEvent('qb-doorlock:server:reportIssue', issue)
    QBCore.Functions.Notify("Problème signalé aux services techniques", "success")
end)

-- Commande pour réparer une porte (mécaniciens)
QBCore.Commands.Add('repairhousedoor', 'Réparer une porte de maison', {
    {name = 'houseId', help = 'ID de la maison'}
}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local houseId = args[1]
    
    -- Vérifier le job
    if Player.PlayerData.job.name ~= 'mechanic' then
        TriggerClientEvent('QBCore:Notify', src, 'Seuls les mécaniciens peuvent réparer les portes', 'error')
        return
    end
    
    if houseId then
        local doorId = 'house_' .. houseId
        
        -- Réinitialiser l'état de la porte
        doorStates[doorId] = true -- Verrouillée par défaut après réparation
        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
        
        -- Donner de l'argent au mécanicien
        Player.Functions.AddMoney('cash', 250, 'door-repair')
        
        TriggerClientEvent('QBCore:Notify', src, 'Porte réparée - $250 reçus', 'success')
        
        -- Notifier le propriétaire si en ligne
        local houseOwner = houseOwners[houseId]
        if houseOwner then
            local Owner = QBCore.Functions.GetPlayerByCitizenId(houseOwner)
            if Owner then
                TriggerClientEvent('QBCore:Notify', Owner.PlayerData.source, 'Votre porte a été réparée', 'success')
            end
        end
    end
end, 'mechanic')

print('[QB-DOORLOCK] Module d\'intégration ps-housing chargé')
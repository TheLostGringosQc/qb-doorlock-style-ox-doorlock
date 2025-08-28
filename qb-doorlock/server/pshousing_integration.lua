-- ================================
-- INTÉGRATION PS-HOUSING POUR QB-DOORLOCK
-- server/pshousing_integration.lua
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Configuration pour ps-housing
Config.PSHousing = {
    Enabled = true,
    AutoCreateDoors = true,     -- Créer automatiquement les portes pour les nouvelles maisons
    DefaultLocked = true,       -- État par défaut des portes de maisons
    UseHouseKeys = true,        -- Utiliser le système de clés de ps-housing
    AllowRealtor = true,        -- Permettre aux agents immobiliers d'accéder
    KeyItemPrefix = 'house_key_', -- Préfixe des items de clés
}

-- Table pour stocker les portes de maisons dynamiques
local houseDoors = {}
local houseOwners = {}
local houseKeys = {}

-- ================================
-- FONCTIONS D'INTÉGRATION PS-HOUSING
-- ================================

-- Fonction pour créer une porte de maison dynamiquement
function CreateHouseDoor(houseId, doorData)
    local doorId = 'house_' .. houseId
    
    -- Configuration de la porte
    local doorConfig = {
        objName = doorData.model or 'v_ilev_fh_frontdoor',
        objCoords = doorData.coords,
        textCoords = vector3(doorData.coords.x, doorData.coords.y, doorData.coords.z + 1.0),
        locked = Config.PSHousing.DefaultLocked,
        distance = 2.5,
        size = 2.0,
        houseId = houseId,
        isHouseDoor = true,
        -- Pas de job requis, utilise le système de propriété de ps-housing
        requiredItems = {},
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:houseInteraction",
                icon = "fas fa-home",
                label = "Utiliser la clé de maison"
            }
        }
    }
    
    -- Ajouter à la config globale
    Config.Doors[doorId] = doorConfig
    houseDoors[houseId] = doorId
    
    -- Synchroniser avec les clients
    TriggerClientEvent('qb-doorlock:client:addHouseDoor', -1, doorId, doorConfig)
    
    return doorId
end

-- Fonction pour supprimer une porte de maison
function RemoveHouseDoor(houseId)
    local doorId = houseDoors[houseId]
    if doorId then
        Config.Doors[doorId] = nil
        houseDoors[houseId] = nil
        
        -- Synchroniser avec les clients
        TriggerClientEvent('qb-doorlock:client:removeHouseDoor', -1, doorId)
    end
end

-- Fonction pour vérifier l'accès à une maison
function HasHouseAccess(source, houseId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Vérifier si c'est le propriétaire
    if houseOwners[houseId] == citizenid then
        return true
    end
    
    -- Vérifier si le joueur a une clé
    local keyItem = Config.PSHousing.KeyItemPrefix .. houseId
    local hasKey = Player.Functions.GetItemByName(keyItem)
    if hasKey and hasKey.amount > 0 then
        return true
    end
    
    -- Vérifier les clés temporaires
    if houseKeys[houseId] and houseKeys[houseId][citizenid] then
        local keyData = houseKeys[houseId][citizenid]
        if keyData.expires > os.time() then
            return true
        else
            -- Clé expirée, la retirer
            houseKeys[houseId][citizenid] = nil
        end
    end
    
    -- Vérifier si c'est un agent immobilier
    if Config.PSHousing.AllowRealtor and Player.PlayerData.job.name == 'realestate' then
        return true
    end
    
    return false
end

-- ================================
-- EVENTS PS-HOUSING
-- ================================

-- Event quand une maison est achetée
RegisterNetEvent('ps-housing:server:houseBought')
AddEventHandler('ps-housing:server:houseBought', function(houseId, buyerCitizenid, houseData)
    -- Mettre à jour le propriétaire
    houseOwners[houseId] = buyerCitizenid
    
    -- Créer la porte si elle n'existe pas
    if not houseDoors[houseId] and Config.PSHousing.AutoCreateDoors then
        local doorData = {
            model = houseData.doorModel,
            coords = houseData.doorCoords
        }
        CreateHouseDoor(houseId, doorData)
    end
    
    -- Donner la clé au nouveau propriétaire
    local Player = QBCore.Functions.GetPlayerByCitizenId(buyerCitizenid)
    if Player then
        local keyItem = Config.PSHousing.KeyItemPrefix .. houseId
        Player.Functions.AddItem(keyItem, 1, false, {
            house = houseId,
            owner = buyerCitizenid,
            created = os.time()
        })
        TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[keyItem], "add")
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Vous avez reçu la clé de votre maison', 'success')
    end
    
    -- Log
    print(string.format('[PS-HOUSING] Maison %s achetée par %s', houseId, buyerCitizenid))
end)

-- Event quand une maison est vendue
RegisterNetEvent('ps-housing:server:houseSold')
AddEventHandler('ps-housing:server:houseSold', function(houseId, sellerCitizenid)
    -- Supprimer le propriétaire
    houseOwners[houseId] = nil
    
    -- Supprimer toutes les clés temporaires
    houseKeys[houseId] = nil
    
    -- Retirer la clé du vendeur
    local Player = QBCore.Functions.GetPlayerByCitizenId(sellerCitizenid)
    if Player then
        local keyItem = Config.PSHousing.KeyItemPrefix .. houseId
        Player.Functions.RemoveItem(keyItem, 99) -- Retirer toutes les clés
    end
    
    -- Verrouiller la porte
    local doorId = houseDoors[houseId]
    if doorId then
        TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
    end
end)

-- Event pour donner une clé temporaire
RegisterNetEvent('ps-housing:server:giveKey')
AddEventHandler('ps-housing:server:giveKey', function(houseId, targetCitizenid, duration)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Vérifier si le joueur est le propriétaire
    if houseOwners[houseId] ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Vous n\'êtes pas le propriétaire de cette maison', 'error')
        return
    end
    
    local Target = QBCore.Functions.GetPlayerByCitizenId(targetCitizenid)
    if not Target then
        TriggerClientEvent('QBCore:Notify', src, 'Joueur introuvable', 'error')
        return
    end
    
    -- Créer la clé temporaire
    if not houseKeys[houseId] then
        houseKeys[houseId] = {}
    end
    
    houseKeys[houseId][targetCitizenid] = {
        expires = os.time() + (duration or 3600), -- 1 heure par défaut
        grantedBy = Player.PlayerData.citizenid
    }
    
    -- Donner l'item clé
    local keyItem = Config.PSHousing.KeyItemPrefix .. houseId
    Target.Functions.AddItem(keyItem, 1, false, {
        house = houseId,
        temporary = true,
        expires = houseKeys[houseId][targetCitizenid].expires
    })
    
    TriggerClientEvent('inventory:client:ItemBox', Target.PlayerData.source, QBCore.Shared.Items[keyItem], "add")
    TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, 'Vous avez reçu une clé temporaire', 'success')
    TriggerClientEvent('QBCore:Notify', src, 'Clé temporaire donnée', 'success')
end)

-- Event pour retirer une clé
RegisterNetEvent('ps-housing:server:removeKey')
AddEventHandler('ps-housing:server:removeKey', function(houseId, targetCitizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Vérifier si le joueur est le propriétaire
    if houseOwners[houseId] ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Vous n\'êtes pas le propriétaire de cette maison', 'error')
        return
    end
    
    -- Supprimer l'accès temporaire
    if houseKeys[houseId] then
        houseKeys[houseId][targetCitizenid] = nil
    end
    
    -- Retirer l'item du joueur s'il est en ligne
    local Target = QBCore.Functions.GetPlayerByCitizenId(targetCitizenid)
    if Target then
        local keyItem = Config.PSHousing.KeyItemPrefix .. houseId
        Target.Functions.RemoveItem(keyItem, 99)
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, 'Votre accès à la maison a été retiré', 'error')
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Accès retiré', 'success')
end)

-- ================================
-- OVERRIDE POUR QB-DOORLOCK
-- ================================

-- Override la fonction d'autorisation pour les maisons
local originalIsAuthorized = IsAuthorized
function IsAuthorized(source, doorId)
    -- Vérifier si c'est une porte de maison
    local door = Config.Doors[doorId]
    if door and door.isHouseDoor then
        return HasHouseAccess(source, door.houseId)
    end
    
    -- Utiliser la fonction originale pour les autres portes
    return originalIsAuthorized(source, doorId)
end

-- ================================
-- EVENTS POUR LE CLIENT
-- ================================

RegisterNetEvent('qb-doorlock:server:houseInteraction')
AddEventHandler('qb-doorlock:server:houseInteraction', function(doorId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local door = Config.Doors[doorId]
    if not door or not door.isHouseDoor then return end
    
    -- Vérifier l'accès
    if not HasHouseAccess(src, door.houseId) then
        TriggerClientEvent('QBCore:Notify', src, 'Vous n\'avez pas la clé de cette maison', 'error')
        return
    end
    
    -- Toggle la porte
    local currentState = doorStates[doorId] or door.locked
    local newState = not currentState
    
    doorStates[doorId] = newState
    TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, newState)
    
    -- Sauvegarder l'état
    DoorLockUtils.SaveDoorState(doorId, newState, Player.PlayerData.citizenid)
    DoorLockUtils.LogActivity(doorId, Player.PlayerData.citizenid, newState and 'lock' or 'unlock', 'house_owner', 0)
    
    -- Notification
    local lockState = newState and "verrouillée" or "déverrouillée"
    TriggerClientEvent('QBCore:Notify', src, "Maison " .. lockState, "success")
end)

-- ================================
-- CALLBACKS POUR PS-HOUSING
-- ================================

-- Callback pour obtenir l'état d'une porte de maison
QBCore.Functions.CreateCallback('qb-doorlock:getHouseDoorState', function(source, cb, houseId)
    local doorId = houseDoors[houseId]
    if doorId then
        cb(doorStates[doorId])
    else
        cb(nil)
    end
end)

-- Callback pour vérifier l'accès d'un joueur à une maison
QBCore.Functions.CreateCallback('qb-doorlock:hasHouseAccess', function(source, cb, houseId)
    cb(HasHouseAccess(source, houseId))
end)

-- ================================
-- EXPORTS POUR PS-HOUSING
-- ================================

-- Export compatible avec ox_doorlock pour ps-housing
exports('editDoorlock', function(doorId, data)
    if not doorId or not data then return false end
    
    -- Si c'est une maison, utiliser notre système
    if type(doorId) == 'string' and doorId:match('^house_') then
        local houseId = doorId:gsub('^house_', '')
        
        if data.locked ~= nil then
            doorStates[doorId] = data.locked
            TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, data.locked)
            return true
        end
    end
    
    return false
end)

-- Export pour créer une porte de maison
exports('createHouseDoor', CreateHouseDoor)
exports('removeHouseDoor', RemoveHouseDoor)
exports('hasHouseAccess', HasHouseAccess)

-- Export pour ps-housing main.lua replacement
exports('setupHouseIntegration', function()
    -- Cette fonction configure l'intégration complète avec ps-housing
    print('[QB-DOORLOCK] Intégration ps-housing activée')
    
    -- Charger les maisons existantes depuis ps-housing
    if GetResourceState('ps-housing') == 'started' then
        local houses = exports['ps-housing']:GetHouses()
        if houses then
            for houseId, houseData in pairs(houses) do
                if houseData.door then
                    CreateHouseDoor(houseId, houseData.door)
                    if houseData.owner then
                        houseOwners[houseId] = houseData.owner
                    end
                end
            end
            print(string.format('[QB-DOORLOCK] %d portes de maisons chargées', #houses))
        end
    end
end)

-- ================================
-- COMMANDES POUR DEBUG/ADMIN
-- ================================

QBCore.Commands.Add('createhousedoor', 'Créer une porte pour une maison', {
    {name = 'houseId', help = 'ID de la maison'},
    {name = 'model', help = 'Modèle de porte (optionnel)'}
}, true, function(source, args)
    local houseId = args[1]
    local model = args[2] or 'v_ilev_fh_frontdoor'
    
    if houseId then
        local playerCoords = GetEntityCoords(GetPlayerPed(source))
        local doorData = {
            model = model,
            coords = playerCoords
        }
        
        local doorId = CreateHouseDoor(houseId, doorData)
        TriggerClientEvent('QBCore:Notify', source, 'Porte créée: ' .. doorId, 'success')
    end
end, 'admin')

QBCore.Commands.Add('givehousekey', 'Donner une clé de maison', {
    {name = 'playerId', help = 'ID du joueur'},
    {name = 'houseId', help = 'ID de la maison'},
    {name = 'duration', help = 'Durée en heures (optionnel)'}
}, true, function(source, args)
    local playerId = tonumber(args[1])
    local houseId = args[2]
    local duration = tonumber(args[3]) or 1
    
    if playerId and houseId then
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            TriggerEvent('ps-housing:server:giveKey', houseId, Player.PlayerData.citizenid, duration * 3600)
        end
    end
end, 'admin')

-- ================================
-- INITIALISATION
-- ================================

Citizen.CreateThread(function()
    -- Attendre que ps-housing soit démarré
    while GetResourceState('ps-housing') ~= 'started' do
        Citizen.Wait(1000)
    end
    
    -- Configurer l'intégration
    if Config.PSHousing.Enabled then
        exports['qb-doorlock']:setupHouseIntegration()
    end
end)
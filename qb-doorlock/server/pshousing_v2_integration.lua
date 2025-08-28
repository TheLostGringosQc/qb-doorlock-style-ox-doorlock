-- ================================
-- COMPATIBILITÉ PS-HOUSING v2.0.x
-- server/pshousing_v2_integration.lua
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Configuration étendue pour v2.0.x
Config.PSHousingV2 = {
    Enabled = true,
    Version = "2.0.x",
    -- Nouvelles fonctionnalités v2.0
    SupportMultipleDoors = true,        -- Support des portes multiples par maison
    SupportGarages = true,              -- Support des garages
    SupportBasements = true,            -- Support des sous-sols
    AutoSyncWithMLO = true,             -- Synchronisation avec les MLO
    UseNewEventSystem = true,           -- Utiliser les nouveaux events v2.0
    
    -- Mapping des nouveaux types de propriétés v2.0
    PropertyTypes = {
        ['house'] = 'house',
        ['apartment'] = 'apartment', 
        ['mansion'] = 'mansion',
        ['office'] = 'office',           -- Nouveau v2.0
        ['warehouse'] = 'warehouse',     -- Nouveau v2.0
        ['garage'] = 'garage',           -- Nouveau v2.0
        ['shop'] = 'shop'                -- Nouveau v2.0
    },
    
    -- Nouveaux modèles de portes v2.0
    DoorModels = {
        ['house'] = {
            main = 'v_ilev_fh_frontdoor',
            back = 'v_ilev_fh_backdoor',
            garage = 'prop_com_gar_door_01'
        },
        ['apartment'] = {
            main = 'v_ilev_genericdoor02',
            service = 'v_ilev_janitor_door'
        },
        ['mansion'] = {
            main = 'v_ilev_lest_bigdoor',
            side = 'v_ilev_fh_frontdoor',
            garage = 'prop_com_gar_door_02',
            basement = 'v_ilev_cor_doorglassa'
        },
        ['office'] = {
            main = 'v_ilev_cor_doorglassa',
            conference = 'v_ilev_genericdoor03'
        },
        ['warehouse'] = {
            main = 'prop_facgate_04_l',
            office = 'v_ilev_cor_doorglassa'
        },
        ['garage'] = {
            main = 'prop_com_gar_door_01',
            office = 'v_ilev_genericdoor02'
        },
        ['shop'] = {
            main = 'v_ilev_cor_doorglassa',
            storage = 'v_ilev_janitor_door'
        }
    }
}

-- Variables pour PS-Housing v2.0
local propertyDoors = {}        -- Stockage des portes par propriété
local propertyOwners = {}       -- Propriétaires par propriété
local propertyTenants = {}      -- Locataires par propriété (nouveau v2.0)
local propertyManagers = {}     -- Gestionnaires par propriété (nouveau v2.0)

-- ================================
-- DÉTECTION DE VERSION PS-HOUSING
-- ================================

local function DetectPSHousingVersion()
    local version = "unknown"
    
    -- Tenter de détecter la version via les exports
    if exports['ps-housing'] then
        -- Vérifier les nouvelles fonctions v2.0
        local hasV2Functions = pcall(function()
            return exports['ps-housing']:GetPropertyData and exports['ps-housing']:GetTenants and exports['ps-housing']:GetPropertyManager
        end)
        
        if hasV2Functions then
            version = "2.0.x"
        else
            version = "1.x.x"
        end
    end
    
    print(string.format('[QB-DOORLOCK] PS-Housing version détectée: %s', version))
    return version
end

-- ================================
-- FONCTIONS V2.0 COMPATIBLES
-- ================================

-- Créer une porte de propriété (multi-portes supportées)
local function CreatePropertyDoor(propertyId, doorData, doorType)
    doorType = doorType or 'main'
    local doorId = string.format('property_%s_%s', propertyId, doorType)
    
    -- Configuration de la porte
    local doorConfig = {
        objName = doorData.model or Config.PSHousingV2.DoorModels.house.main,
        objCoords = doorData.coords,
        textCoords = vector3(doorData.coords.x, doorData.coords.y, doorData.coords.z + 1.0),
        locked = doorData.locked or true,
        distance = doorData.distance or 2.5,
        size = doorData.size or 2.0,
        propertyId = propertyId,
        doorType = doorType,
        isPropertyDoor = true,
        
        -- Nouveau système d'autorisation v2.0
        authorizedTypes = {'owner', 'tenant', 'manager', 'realtor'},
        
        requiredItems = doorData.requiredItems or {},
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:propertyInteraction",
                icon = GetDoorIcon(doorType),
                label = GetDoorLabel(doorType),
                propertyId = propertyId,
                doorType = doorType
            }
        },
        
        -- Nouveau système de permissions v2.0
        permissions = {
            owner = true,
            tenant = doorData.tenantAccess ~= false,
            manager = true,
            realtor = true,
            guest = false
        }
    }
    
    -- Ajouter à la config globale
    Config.Doors[doorId] = doorConfig
    
    -- Stocker dans le mapping des propriétés
    if not propertyDoors[propertyId] then
        propertyDoors[propertyId] = {}
    end
    propertyDoors[propertyId][doorType] = doorId
    
    -- Synchroniser avec les clients
    TriggerClientEvent('qb-doorlock:client:addPropertyDoor', -1, doorId, doorConfig)
    
    return doorId
end

-- Obtenir les icônes par type de porte
function GetDoorIcon(doorType)
    local icons = {
        main = "fas fa-home",
        back = "fas fa-door-open", 
        garage = "fas fa-warehouse",
        basement = "fas fa-stairs",
        office = "fas fa-briefcase",
        storage = "fas fa-box",
        service = "fas fa-tools",
        conference = "fas fa-users"
    }
    return icons[doorType] or "fas fa-door-closed"
end

-- Obtenir les labels par type de porte
function GetDoorLabel(doorType)
    local labels = {
        main = "Entrée principale",
        back = "Entrée arrière",
        garage = "Garage", 
        basement = "Sous-sol",
        office = "Bureau",
        storage = "Stockage",
        service = "Service",
        conference = "Salle de réunion"
    }
    return labels[doorType] or "Porte"
end

-- Vérifier l'accès à une propriété (v2.0 compatible)
local function HasPropertyAccess(source, propertyId, doorType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Vérifier si c'est le propriétaire
    if propertyOwners[propertyId] == citizenid then
        return true, 'owner'
    end
    
    -- Vérifier si c'est un locataire (nouveau v2.0)
    if propertyTenants[propertyId] then
        for _, tenant in ipairs(propertyTenants[propertyId]) do
            if tenant.citizenid == citizenid then
                -- Vérifier les permissions du locataire pour ce type de porte
                if tenant.permissions and tenant.permissions[doorType] then
                    return true, 'tenant'
                end
            end
        end
    end
    
    -- Vérifier si c'est un gestionnaire (nouveau v2.0)
    if propertyManagers[propertyId] then
        for _, manager in ipairs(propertyManagers[propertyId]) do
            if manager.citizenid == citizenid then
                return true, 'manager'
            end
        end
    end
    
    -- Vérifier les clés physiques
    local keyItem = string.format('property_key_%s', propertyId)
    local hasKey = Player.Functions.GetItemByName(keyItem)
    if hasKey and hasKey.amount > 0 then
        -- Vérifier les métadonnées de la clé pour le type de porte
        if hasKey.info and hasKey.info.doorAccess then
            if hasKey.info.doorAccess[doorType] then
                return true, 'key'
            end
        else
            return true, 'key' -- Clé générique
        end
    end
    
    -- Vérifier si c'est un agent immobilier
    if Player.PlayerData.job.name == 'realestate' then
        return true, 'realtor'
    end
    
    return false, 'none'
end

-- ================================
-- EVENTS PS-HOUSING V2.0
-- ================================

-- Nouveau système d'events v2.0
RegisterNetEvent('ps-housing:server:propertyPurchased')
AddEventHandler('ps-housing:server:propertyPurchased', function(propertyId, buyerData, propertyData)
    print(string.format('[QB-DOORLOCK] Propriété achetée: %s par %s', propertyId, buyerData.citizenid))
    
    -- Mettre à jour le propriétaire
    propertyOwners[propertyId] = buyerData.citizenid
    
    -- Créer les portes selon le type de propriété
    if propertyData.doors then
        for doorType, doorData in pairs(propertyData.doors) do
            CreatePropertyDoor(propertyId, doorData, doorType)
        end
    else
        -- Fallback - créer une porte principale par défaut
        local mainDoorData = {
            coords = propertyData.entrance or propertyData.coords,
            model = Config.PSHousingV2.DoorModels[propertyData.type].main
        }
        CreatePropertyDoor(propertyId, mainDoorData, 'main')
    end
    
    -- Donner les clés au nouveau propriétaire
    local Player = QBCore.Functions.GetPlayerByCitizenId(buyerData.citizenid)
    if Player then
        GivePropertyKeys(Player, propertyId, propertyData)
    end
end)

-- Event pour la vente de propriété
RegisterNetEvent('ps-housing:server:propertySold')
AddEventHandler('ps-housing:server:propertySold', function(propertyId, sellerData, buyerData)
    print(string.format('[QB-DOORLOCK] Propriété vendue: %s de %s à %s', propertyId, sellerData.citizenid, buyerData and buyerData.citizenid or 'SYSTEM'))
    
    -- Supprimer l'ancien propriétaire
    propertyOwners[propertyId] = buyerData and buyerData.citizenid or nil
    
    -- Nettoyer les locataires et gestionnaires
    propertyTenants[propertyId] = nil
    propertyManagers[propertyId] = nil
    
    -- Verrouiller toutes les portes
    if propertyDoors[propertyId] then
        for doorType, doorId in pairs(propertyDoors[propertyId]) do
            doorStates[doorId] = true
            TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, true)
        end
    end
    
    -- Retirer les clés de l'ancien propriétaire
    local Seller = QBCore.Functions.GetPlayerByCitizenId(sellerData.citizenid)
    if Seller then
        RemovePropertyKeys(Seller, propertyId)
    end
    
    -- Donner les clés au nouveau propriétaire
    if buyerData then
        local Buyer = QBCore.Functions.GetPlayerByCitizenId(buyerData.citizenid)
        if Buyer then
            -- Récupérer les données de la propriété
            QBCore.Functions.TriggerCallback('ps-housing:server:getPropertyData', function(propertyData)
                if propertyData then
                    GivePropertyKeys(Buyer, propertyId, propertyData)
                end
            end, propertyId)
        end
    end
end)

-- Nouveau event pour les locataires v2.0
RegisterNetEvent('ps-housing:server:tenantAdded')
AddEventHandler('ps-housing:server:tenantAdded', function(propertyId, tenantData, permissions)
    if not propertyTenants[propertyId] then
        propertyTenants[propertyId] = {}
    end
    
    table.insert(propertyTenants[propertyId], {
        citizenid = tenantData.citizenid,
        permissions = permissions or {main = true}, -- Accès principal par défaut
        addedDate = os.time()
    })
    
    -- Donner une clé limitée au locataire
    local Tenant = QBCore.Functions.GetPlayerByCitizenId(tenantData.citizenid)
    if Tenant then
        GiveTenantKey(Tenant, propertyId, permissions)
    end
    
    print(string.format('[QB-DOORLOCK] Locataire ajouté: %s à la propriété %s', tenantData.citizenid, propertyId))
end)

-- Event pour retirer un locataire v2.0
RegisterNetEvent('ps-housing:server:tenantRemoved')
AddEventHandler('ps-housing:server:tenantRemoved', function(propertyId, tenantCitizenid)
    if propertyTenants[propertyId] then
        for i, tenant in ipairs(propertyTenants[propertyId]) do
            if tenant.citizenid == tenantCitizenid then
                table.remove(propertyTenants[propertyId], i)
                break
            end
        end
    end
    
    -- Retirer la clé du locataire
    local Tenant = QBCore.Functions.GetPlayerByCitizenId(tenantCitizenid)
    if Tenant then
        RemovePropertyKeys(Tenant, propertyId)
    end
    
    print(string.format('[QB-DOORLOCK] Locataire retiré: %s de la propriété %s', tenantCitizenid, propertyId))
end)

-- Nouveau event pour les gestionnaires v2.0
RegisterNetEvent('ps-housing:server:managerAdded')
AddEventHandler('ps-housing:server:managerAdded', function(propertyId, managerData)
    if not propertyManagers[propertyId] then
        propertyManagers[propertyId] = {}
    end
    
    table.insert(propertyManagers[propertyId], {
        citizenid = managerData.citizenid,
        addedDate = os.time(),
        permissions = 'full' -- Gestionnaires ont accès complet
    })
    
    -- Donner une clé de gestionnaire
    local Manager = QBCore.Functions.GetPlayerByCitizenId(managerData.citizenid)
    if Manager then
        GiveManagerKey(Manager, propertyId)
    end
    
    print(string.format('[QB-DOORLOCK] Gestionnaire ajouté: %s à la propriété %s', managerData.citizenid, propertyId))
end)

-- ================================
-- FONCTIONS DE GESTION DES CLÉS V2.0
-- ================================

-- Donner les clés de propriétaire (accès complet)
function GivePropertyKeys(Player, propertyId, propertyData)
    local keyItem = string.format('property_key_%s', propertyId)
    
    -- Créer la clé avec métadonnées complètes
    local keyInfo = {
        property = propertyId,
        type = 'owner',
        propertyType = propertyData.type,
        doorAccess = {},
        created = os.time()
    }
    
    -- Accès à toutes les portes pour le propriétaire
    if propertyDoors[propertyId] then
        for doorType, _ in pairs(propertyDoors[propertyId]) do
            keyInfo.doorAccess[doorType] = true
        end
    else
        keyInfo.doorAccess.main = true -- Au minimum l'accès principal
    end
    
    Player.Functions.AddItem(keyItem, 1, false, keyInfo)
    TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[keyItem] or {name = keyItem, label = 'Clé de Propriété'}, "add")
    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Vous avez reçu les clés de votre propriété', 'success')
end

-- Donner une clé de locataire (accès limité)
function GiveTenantKey(Player, propertyId, permissions)
    local keyItem = string.format('property_key_%s_tenant', propertyId)
    
    local keyInfo = {
        property = propertyId,
        type = 'tenant',
        doorAccess = permissions or {main = true},
        created = os.time(),
        expires = os.time() + (30 * 24 * 3600) -- 30 jours par défaut
    }
    
    Player.Functions.AddItem(keyItem, 1, false, keyInfo)
    TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[keyItem] or {name = keyItem, label = 'Clé de Locataire'}, "add")
    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Vous avez reçu une clé de locataire', 'success')
end

-- Donner une clé de gestionnaire (accès étendu)
function GiveManagerKey(Player, propertyId)
    local keyItem = string.format('property_key_%s_manager', propertyId)
    
    local keyInfo = {
        property = propertyId,
        type = 'manager',
        doorAccess = {
            main = true,
            office = true,
            storage = true
            -- Pas d'accès aux espaces privés comme garage/basement
        },
        created = os.time()
    }
    
    Player.Functions.AddItem(keyItem, 1, false, keyInfo)
    TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[keyItem] or {name = keyItem, label = 'Clé de Gestionnaire'}, "add")
    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Vous avez reçu une clé de gestionnaire', 'success')
end

-- Retirer toutes les clés d'une propriété
function RemovePropertyKeys(Player, propertyId)
    local keyItems = {
        string.format('property_key_%s', propertyId),
        string.format('property_key_%s_tenant', propertyId),
        string.format('property_key_%s_manager', propertyId)
    }
    
    for _, keyItem in ipairs(keyItems) do
        Player.Functions.RemoveItem(keyItem, 99) -- Retirer toutes les instances
    end
    
    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Vos clés de propriété ont été retirées', 'error')
end

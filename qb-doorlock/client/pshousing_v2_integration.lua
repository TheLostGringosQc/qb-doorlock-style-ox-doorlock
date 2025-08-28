-- ================================
-- INTEGRATION CLIENT V2.0
-- ================================

RegisterNetEvent('qb-doorlock:server:propertyInteraction')
AddEventHandler('qb-doorlock:server:propertyInteraction', function(doorId, propertyId, doorType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local door = Config.Doors[doorId]
    if not door or not door.isPropertyDoor then return end
    
    -- Vérifier l'accès avec le nouveau système v2.0
    local hasAccess, accessType = HasPropertyAccess(src, propertyId, doorType)
    
    if not hasAccess then
        TriggerClientEvent('QBCore:Notify', src, string.format('Vous n\'avez pas accès à cette %s', GetDoorLabel(doorType)), 'error')
        return
    end
    
    -- Toggle la porte
    local currentState = doorStates[doorId] or door.locked
    local newState = not currentState
    
    doorStates[doorId] = newState
    TriggerClientEvent('qb-doorlock:client:setState', -1, doorId, newState)
    
    -- Sauvegarder l'état
    DoorLockUtils.SaveDoorState(doorId, newState, Player.PlayerData.citizenid)
    DoorLockUtils.LogActivity(doorId, Player.PlayerData.citizenid, newState and 'lock' or 'unlock', accessType, 0)
    
    -- Notification spéciale selon le type
    local lockState = newState and "verrouillée" or "déverrouillée"
    local doorLabel = GetDoorLabel(doorType)
    TriggerClientEvent('QBCore:Notify', src, string.format("%s %s", doorLabel, lockState), "success")
end)

-- ================================
-- INITIALISATION V2.0
-- ================================

-- Chargement au démarrage avec détection de version
Citizen.CreateThread(function()
    -- Attendre que ps-housing soit démarré
    while GetResourceState('ps-housing') ~= 'started' do
        Citizen.Wait(1000)
    end
    
    -- Détecter la version
    local version = DetectPSHousingVersion()
    Config.PSHousingV2.DetectedVersion = version
    
    if version == "2.0.x" and Config.PSHousingV2.Enabled then
        -- Charger les propriétés existantes avec la nouvelle API v2.0
        if exports['ps-housing'] and exports['ps-housing'].GetAllProperties then
            local properties = exports['ps-housing']:GetAllProperties()
            
            if properties then
                for propertyId, propertyData in pairs(properties) do
                    -- Charger le propriétaire
                    if propertyData.owner then
                        propertyOwners[propertyId] = propertyData.owner
                    end
                    
                    -- Charger les locataires
                    if propertyData.tenants then
                        propertyTenants[propertyId] = propertyData.tenants
                    end
                    
                    -- Charger les gestionnaires
                    if propertyData.managers then
                        propertyManagers[propertyId] = propertyData.managers
                    end
                    
                    -- Créer les portes
                    if propertyData.doors then
                        for doorType, doorData in pairs(propertyData.doors) do
                            CreatePropertyDoor(propertyId, doorData, doorType)
                        end
                    end
                end
                
                print(string.format('[QB-DOORLOCK] %d propriétés PS-Housing v2.0 chargées', #properties))
            end
        end
        
        print('[QB-DOORLOCK] Intégration PS-Housing v2.0.x activée')
    else
        print(string.format('[QB-DOORLOCK] PS-Housing v%s détecté, utilisation du mode de compatibilité', version))
    end
end)

-- Exports pour PS-Housing v2.0
exports('createPropertyDoor', CreatePropertyDoor)
exports('hasPropertyAccess', HasPropertyAccess)
exports('getPropertyDoors', function(propertyId)
    return propertyDoors[propertyId]
end)
exports('getPropertyOwner', function(propertyId)
    return propertyOwners[propertyId]
end)
exports('getPropertyTenants', function(propertyId)
    return propertyTenants[propertyId]
end)
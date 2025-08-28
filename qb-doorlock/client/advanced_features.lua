-- ================================
-- CLIENT AVANCÉ QB-DOORLOCK
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables étendues
local doors = {}
local PlayerJob = {}
local isNearDoor = false
local currentDoorId = nil
local uiShown = false

-- NUI Callbacks pour l'interface de code
RegisterNUICallback('submitCode', function(data, cb)
    local code = data.code
    local doorId = data.doorId
    
    TriggerServerEvent('qb-doorlock:server:checkCode', doorId, code)
    cb('ok')
end)

RegisterNUICallback('closeCodeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Fonctions utilitaires étendues
local function PlayLockSound(locked)
    local soundName = locked and Config.Sounds.lock or Config.Sounds.unlock
    PlaySoundFromEntity(-1, soundName, PlayerPedId(), 0, 0, 0)
end

local function DoLockAnimation()
    local ped = PlayerPedId()
    local animDict = "anim@heists@keycard@"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(1)
    end
    
    TaskPlayAnim(ped, animDict, "exit", 8.0, 1.0, -1, 48, 0, 0, 0, 0)
    Citizen.Wait(1500)
    ClearPedTasks(ped)
end

-- Interface utilisateur améliorée
local function ShowDoorUI(doorId, doorConfig)
    local door = doors[doorId]
    if not door then return end
    
    local lockState = door.locked and "VERROUILLÉE" or "OUVERTE"
    local color = door.locked and "~r~" or "~g~"
    local icon = door.locked and "🔒" or "🔓"
    
    -- Affichage 3D amélioré
    if Config.Use3DText then
        SetTextScale(0.4, 0.4)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(color .. icon .. " " .. lockState)
        SetDrawOrigin(doorConfig.textCoords.x, doorConfig.textCoords.y, doorConfig.textCoords.z, 0)
        DrawText(0.0, 0.0)
        ClearDrawOrigin()
    end
    
    -- Informations détaillées quand proche
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - doorConfig.textCoords)
    
    if distance < 1.5 then
        local infoText = ""
        
        if IsAuthorized(doorId) then
            infoText = "~g~[E]~w~ " .. (door.locked and "Déverrouiller" or "Verrouiller")
            
            -- Afficher les items requis
            if doorConfig.requiredItems then
                infoText = infoText .. "\n~y~Items requis:~w~"
                for _, item in ipairs(doorConfig.requiredItems) do
                    local hasItem = exports['ps-inventory']:HasItem(item.item, 1)
                    local status = hasItem and "~g~✓~w~" or "~r~✗~w~"
                    infoText = infoText .. "\n" .. status .. " " .. QBCore.Shared.Items[item.item].label
                end
            end
        else
            infoText = "~r~Accès refusé~w~"
            
            -- Raison du refus
            if doorConfig.authorizedJobs then
                local playerJob = QBCore.Functions.GetPlayerData().job.name
                local hasJob = false
                for _, job in ipairs(doorConfig.authorizedJobs) do
                    if playerJob == job then hasJob = true break end
                end
                if not hasJob then
                    infoText = infoText .. "\n~r~Job requis:~w~ " .. table.concat(doorConfig.authorizedJobs, ", ")
                end
            end
        end
        
        QBCore.Functions.DrawText(infoText, 'left')
        currentDoorId = doorId
        isNearDoor = true
    end
end

-- Système de groupes de portes
local function ToggleDoorGroup(groupId)
    local group = Config.DoorGroups[groupId]
    if not group then return end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Vérifier l'autorisation pour le groupe
    local hasJob = false
    if group.authorizedJobs then
        for _, job in ipairs(group.authorizedJobs) do
            if PlayerData.job.name == job then
                hasJob = true
                break
            end
        end
    end
    
    if not hasJob then
        QBCore.Functions.Notify("Vous n'avez pas l'autorisation pour ce groupe", "error")
        return
    end
    
    -- Vérifier le grade si requis
    if group.requiredGrade and PlayerData.job.grade.level < group.requiredGrade then
        QBCore.Functions.Notify("Grade insuffisant", "error")
        return
    end
    
    -- Toggle toutes les portes du groupe
    for _, doorId in ipairs(group.doors) do
        if doors[doorId] then
            TriggerServerEvent('qb-doorlock:server:toggleGroup', groupId, doorId)
        end
    end
    
    QBCore.Functions.Notify(string.format("Groupe %s activé", groupId), "success")
end

-- Système de codes d'accès
local function RequestAccessCode(doorId)
    local door = Config.Doors[doorId]
    if not door or not door.requiresCode then return end
    
    -- Ouvrir l'interface NUI pour saisir le code
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "showCodeInput",
        doorId = doorId,
        doorLabel = door.label or doorId
    })
end

-- Fonction de toggle améliorée
local function AdvancedToggleLock(doorId)
    local door = Config.Doors[doorId]
    if not door then return end
    
    -- Vérifications préliminaires
    if not IsAuthorized(doorId) then
        -- Message spécifique selon le type d'échec
        local PlayerData = QBCore.Functions.GetPlayerData()
        
        if door.authorizedJobs then
            local hasJob = false
            for _, job in ipairs(door.authorizedJobs) do
                if PlayerData.job.name == job then hasJob = true break end
            end
            if not hasJob then
                local message = door.notifications and door.notifications.unauthorized or "Job non autorisé"
                QBCore.Functions.Notify(message, "error")
                return
            end
        end
        
        if not HasRequiredItems(doorId) then
            local message = "Items manquants:"
            for _, item in ipairs(door.requiredItems or {}) do
                local hasItem = exports['ps-inventory']:HasItem(item.item, 1)
                if not hasItem then
                    message = message .. "\n- " .. (QBCore.Shared.Items[item.item].label or item.item)
                end
            end
            QBCore.Functions.Notify(message, "error")
            return
        end
    end
    
    -- Vérifier les horaires si configurés
    if door.schedule then
        local currentHour = tonumber(os.date("%H"))
        local isWithinSchedule = currentHour >= door.schedule.openHour and currentHour < door.schedule.closeHour
        
        if not isWithinSchedule and not door.schedule.allowAfterHours then
            QBCore.Functions.Notify("Accès restreint en dehors des heures d'ouverture", "error")
            return
        end
    end
    
    -- Effectuer l'action
    DoLockAnimation()
    TriggerServerEvent('qb-doorlock:server:toggleLock', doorId)
end

-- Thread principal amélioré
local function EnhancedMainThread()
    Citizen.CreateThread(function()
        while true do
            local wait = 1000
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            isNearDoor = false
            currentDoorId = nil
            
            for doorId, doorConfig in pairs(Config.Doors) do
                local distance = #(playerCoords - doorConfig.textCoords)
                
                if distance < doorConfig.distance then
                    wait = 0
                    ShowDoorUI(doorId, doorConfig)
                end
            end
            
            -- Gestion de l'affichage UI
            if not isNearDoor and uiShown then
                QBCore.Functions.HideText()
                uiShown = false
            elseif isNearDoor and not uiShown then
                uiShown = true
            end
            
            Citizen.Wait(wait)
        end
    end)
end

-- Thread pour les contrôles
local function ControlThread()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            
            if isNearDoor and currentDoorId then
                -- Interaction principale
                if IsControlJustReleased(0, 38) then -- E
                    local door = Config.Doors[currentDoorId]
                    if door.requiresCode then
                        RequestAccessCode(currentDoorId)
                    else
                        AdvancedToggleLock(currentDoorId)
                    end
                end
                
                -- Touches supplémentaires pour les groupes
                if IsControlJustReleased(0, 74) then -- H
                    -- Chercher si cette porte fait partie d'un groupe
                    for groupId, group in pairs(Config.DoorGroups) do
                        for _, doorId in ipairs(group.doors) do
                            if doorId == currentDoorId then
                                ToggleDoorGroup(groupId)
                                break
                            end
                        end
                    end
                end
            else
                Citizen.Wait(500)
            end
        end
    end)
end

-- Events étendus
RegisterNetEvent('qb-doorlock:client:toggleLock')
AddEventHandler('qb-doorlock:client:toggleLock', function(data)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local doorId = nil
    local minDistance = math.huge
    
    for id, doorConfig in pairs(Config.Doors) do
        local distance = #(playerCoords - doorConfig.objCoords)
        if distance < minDistance and distance < doorConfig.distance then
            minDistance = distance
            doorId = id
        end
    end
    
    if doorId then
        local door = Config.Doors[doorId]
        if door.requiresCode then
            RequestAccessCode(doorId)
        else
            AdvancedToggleLock(doorId)
        end
    end
end)

RegisterNetEvent('qb-doorlock:client:requestCode')
AddEventHandler('qb-doorlock:client:requestCode', function(data)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local doorId = nil
    local minDistance = math.huge
    
    for id, doorConfig in pairs(Config.Doors) do
        local distance = #(playerCoords - doorConfig.objCoords)
        if distance < minDistance and distance < doorConfig.distance then
            minDistance = distance
            doorId = id
        end
    end
    
    if doorId then
        RequestAccessCode(doorId)
    end
end)

RegisterNetEvent('qb-doorlock:client:codeResult')
AddEventHandler('qb-doorlock:client:codeResult', function(success, doorId)
    SetNuiFocus(false, false)
    
    if success then
        local door = doors[doorId]
        if door then
            door.locked = not door.locked
            PlayLockSound(door.locked)
            
            local message = door.locked and "Porte verrouillée" or "Porte déverrouillée"
            QBCore.Functions.Notify(message, "success")
        end
    else
        QBCore.Functions.Notify("Code incorrect", "error")
    end
end)

RegisterNetEvent('qb-doorlock:client:reloadConfig')
AddEventHandler('qb-doorlock:client:reloadConfig', function()
    -- Réinitialiser qb-target
    for doorId, door in pairs(doors) do
        if door.object and DoesEntityExist(door.object) then
            exports['qb-target']:RemoveTargetEntity(door.object)
        end
    end
    
    -- Recharger
    doors = {}
    InitializeDoors()
    QBCore.Functions.Notify("Configuration rechargée", "success")
end)

-- Initialisation au spawn
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Citizen.Wait(2000) -- Attendre que tout soit chargé
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    PlayerJob = PlayerData.job
    
    InitializeDoors()
    EnhancedMainThread()
    ControlThread()
end)

-- Exports étendus
exports('ToggleLockAdvanced', AdvancedToggleLock)
exports('ToggleDoorGroup', ToggleDoorGroup)
exports('RequestAccessCode', RequestAccessCode)
exports('GetNearbyDoors', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearbyDoors = {}
    
    for doorId, doorConfig in pairs(Config.Doors) do
        local distance = #(playerCoords - doorConfig.objCoords)
        if distance < 10.0 then
            table.insert(nearbyDoors, {
                id = doorId,
                distance = distance,
                locked = doors[doorId] and doors[doorId].locked or nil
            })
        end
    end
    
    return nearbyDoors
end)
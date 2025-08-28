-- ================================
-- CLIENT MAIN - QB-DOORLOCK
-- client/main.lua
-- Script client principal
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables globales
local doors = {}
local PlayerJob = {}
local isNearDoor = false
local currentDoorId = nil
local uiShown = false

-- ================================
-- FONCTIONS UTILITAIRES
-- ================================

-- Fonction pour arrondir les nombres
local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Fonction pour afficher du texte 3D
local function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Fonction pour jouer les sons de verrouillage
local function PlayLockSound(locked)
    local soundName = locked and Config.Sounds.lock or Config.Sounds.unlock
    PlaySoundFromEntity(-1, soundName, PlayerPedId(), 0, 0, 0)
end

-- Fonction pour l'animation de verrouillage
local function DoLockAnimation()
    local ped = PlayerPedId()
    RequestAnimDict("anim@heists@keycard@")
    while not HasAnimDictLoaded("anim@heists@keycard@") do
        Citizen.Wait(1)
    end
    TaskPlayAnim(ped, "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 48, 0, 0, 0, 0)
    Citizen.Wait(1500)
    ClearPedTasks(ped)
end

-- ================================
-- SYSTÈME D'AUTORISATION
-- ================================

-- Vérifier si le joueur a les items requis
local function HasRequiredItems(doorId)
    local door = Config.Doors[doorId]
    if not door.requiredItems then return true end
    
    for _, requiredItem in ipairs(door.requiredItems) do
        local hasItem = exports['ps-inventory']:HasItem(requiredItem.item, 1)
        if not hasItem then
            return false
        end
    end
    return true
end

-- Vérifier l'autorisation d'accès à une porte
function IsAuthorized(doorId)
    local door = Config.Doors[doorId]
    if not door then return false end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Vérification du job
    if door.authorizedJobs then
        local hasJob = false
        for _, job in ipairs(door.authorizedJobs) do
            if PlayerData.job.name == job then
                hasJob = true
                break
            end
        end
        if not hasJob then return false end
    end
    
    -- Vérification du grade
    if door.authorizedGrades then
        local playerGrade = PlayerData.job.grade.level
        local hasGrade = false
        for _, requiredGrade in ipairs(door.authorizedGrades) do
            if playerGrade >= requiredGrade then
                hasGrade = true
                break
            end
        end
        if not hasGrade then return false end
    end
    
    -- Vérification des items requis
    if not HasRequiredItems(doorId) then
        return false
    end
    
    return true
end

-- ================================
-- GESTION DES PORTES
-- ================================

-- Fonction pour toggle une porte
local function ToggleLock(doorId)
    if not IsAuthorized(doorId) then
        QBCore.Functions.Notify("Vous n'avez pas l'autorisation", "error")
        return
    end
    
    local door = doors[doorId]
    if door then
        -- Animation
        DoLockAnimation()
        
        -- Envoyer au serveur
        TriggerServerEvent('qb-doorlock:server:toggleLock', doorId)
    end
end

-- Initialiser les portes
local function InitializeDoors()
    for doorId, doorConfig in pairs(Config.Doors) do
        local door = GetClosestObjectOfType(
            doorConfig.objCoords.x, 
            doorConfig.objCoords.y, 
            doorConfig.objCoords.z, 
            1.0, 
            GetHashKey(doorConfig.objName), 
            false, false, false
        )
        
        if door ~= 0 then
            doors[doorId] = {
                object = door,
                locked = doorConfig.locked or false
            }
            
            -- Définir l'état initial
            FreezeEntityPosition(door, doorConfig.locked or false)
            
            -- Ajouter qb-target si activé
            if Config.UseTarget and doorConfig.targetOptions then
                exports['qb-target']:AddTargetEntity(door, {
                    options = doorConfig.targetOptions,
                    distance = doorConfig.distance or 2.5
                })
            end
        else
            print(string.format('[QB-DOORLOCK] Porte non trouvée: %s aux coordonnées %s', doorConfig.objName, doorConfig.objCoords))
        end
    end
    
    print(string.format('[QB-DOORLOCK] %d portes initialisées côté client', #doors))
end

-- ================================
-- INTERFACE UTILISATEUR
-- ================================

-- Afficher l'interface près d'une porte
local function ShowDoorUI(doorId, doorConfig)
    local door = doors[doorId]
    if not door then return end
    
    local lockState = door.locked and "VERROUILLÉE" or "OUVERTE"
    local color = door.locked and "~r~" or "~g~"
    local icon = door.locked and "🔒" or "🔓"
    
    -- Affichage 3D
    if Config.Use3DText then
        DrawText3Ds(
            doorConfig.textCoords.x,
            doorConfig.textCoords.y,
            doorConfig.textCoords.z,
            color .. icon .. " " .. lockState
        )
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
                    local itemLabel = QBCore.Shared.Items[item.item] and QBCore.Shared.Items[item.item].label or item.item
                    infoText = infoText .. "\n" .. status .. " " .. itemLabel
                end
            end
        else
            infoText = "~r~Accès refusé~w~"
            
            -- Raison du refus
            local PlayerData = QBCore.Functions.GetPlayerData()
            if doorConfig.authorizedJobs then
                local playerJob = PlayerData.job.name
                local hasJob = false
                for _, job in ipairs(doorConfig.authorizedJobs) do
                    if playerJob == job then hasJob = true break end
                end
                if not hasJob then
                    infoText = infoText .. "\n~r~Job requis:~w~ " .. table.concat(doorConfig.authorizedJobs, ", ")
                end
            end
            
            if doorConfig.authorizedGrades and PlayerData.job then
                local playerGrade = PlayerData.job.grade.level
                local hasGrade = false
                for _, requiredGrade in ipairs(doorConfig.authorizedGrades) do
                    if playerGrade >= requiredGrade then hasGrade = true break end
                end
                if not hasGrade then
                    infoText = infoText .. "\n~r~Grade insuffisant~w~"
                end
            end
        end
        
        QBCore.Functions.DrawText(infoText, 'left')
        currentDoorId = doorId
        isNearDoor = true
    end
end

-- ================================
-- THREADS PRINCIPAUX
-- ================================

-- Thread principal pour l'affichage des portes
local function MainThread()
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
                -- Interaction avec E si pas de qb-target ou si UseKeyPress activé
                if (not Config.UseTarget or Config.UseKeyPress) and IsControlJustReleased(0, 38) then -- E key
                    local door = Config.Doors[currentDoorId]
                    if door and door.requiresCode then
                        -- Ouvrir l'interface NUI pour le code
                        TriggerEvent('qb-doorlock:client:requestCode', {doorId = currentDoorId})
                    else
                        ToggleLock(currentDoorId)
                    end
                end
            else
                Citizen.Wait(500)
            end
        end
    end)
end

-- ================================
-- ÉVÉNEMENTS RÉSEAU
-- ================================

-- Event pour toggle une porte via qb-target
RegisterNetEvent('qb-doorlock:client:toggleLock')
AddEventHandler('qb-doorlock:client:toggleLock', function(data)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local doorId = nil
    local minDistance = math.huge
    
    -- Trouver la porte la plus proche
    for id, doorConfig in pairs(Config.Doors) do
        local distance = #(playerCoords - doorConfig.objCoords)
        if distance < minDistance and distance < doorConfig.distance then
            minDistance = distance
            doorId = id
        end
    end
    
    if doorId then
        local door = Config.Doors[doorId]
        if door and door.requiresCode then
            TriggerEvent('qb-doorlock:client:requestCode', {doorId = doorId})
        else
            ToggleLock(doorId)
        end
    end
end)

-- Event pour mettre à jour l'état d'une porte
RegisterNetEvent('qb-doorlock:client:setState')
AddEventHandler('qb-doorlock:client:setState', function(doorId, state)
    local door = doors[doorId]
    if door then
        door.locked = state
        FreezeEntityPosition(door.object, state)
        
        -- Son de verrouillage
        PlayLockSound(state)
    end
end)

-- Event pour demander un code d'accès
RegisterNetEvent('qb-doorlock:client:requestCode')
AddEventHandler('qb-doorlock:client:requestCode', function(data)
    local doorId = data.doorId or currentDoorId
    if not doorId then return end
    
    local door = Config.Doors[doorId]
    if door and door.requiresCode then
        -- Utiliser le UI Manager si disponible
        if exports['qb-doorlock'] and exports['qb-doorlock'].ShowCodeInput then
            exports['qb-doorlock']:ShowCodeInput(doorId, door.label or doorId, function(code)
                if code then
                    TriggerServerEvent('qb-doorlock:server:checkCode', doorId, code)
                end
            end)
        else
            -- Fallback simple
            local code = nil
            local keyboard = exports['qb-input']:ShowInput({
                header = "Code d'accès",
                submitText = "Valider",
                inputs = {
                    {
                        text = "Code (4 chiffres)",
                        name = "code",
                        type = "password",
                        isRequired = true,
                        maxlength = 4
                    }
                }
            })
            
            if keyboard then
                code = keyboard.code
                TriggerServerEvent('qb-doorlock:server:checkCode', doorId, code)
            end
        end
    end
end)

-- Event pour le résultat du code
RegisterNetEvent('qb-doorlock:client:codeResult')
AddEventHandler('qb-doorlock:client:codeResult', function(success, doorId)
    if success then
        QBCore.Functions.Notify("Code correct", "success")
    else
        QBCore.Functions.Notify("Code incorrect", "error")
    end
end)

-- Event pour recharger la configuration
RegisterNetEvent('qb-doorlock:client:reloadConfig')
AddEventHandler('qb-doorlock:client:reloadConfig', function()
    -- Réinitialiser qb-target
    if Config.UseTarget then
        for doorId, door in pairs(doors) do
            if door.object and DoesEntityExist(door.object) then
                exports['qb-target']:RemoveTargetEntity(door.object)
            end
        end
    end
    
    -- Recharger
    doors = {}
    InitializeDoors()
    QBCore.Functions.Notify("Configuration rechargée", "success")
end)

-- Event pour mise à jour du job
RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

-- ================================
-- INITIALISATION
-- ================================

-- Initialisation au chargement du joueur
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Citizen.Wait(2000) -- Attendre que tout soit chargé
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    PlayerJob = PlayerData.job
    
    -- Récupérer les états des portes depuis le serveur
    QBCore.Functions.TriggerCallback('qb-doorlock:server:getDoorStates', function(states)
        for doorId, state in pairs(states) do
            if doors[doorId] then
                doors[doorId].locked = state
                FreezeEntityPosition(doors[doorId].object, state)
            end
        end
    end)
    
    InitializeDoors()
    MainThread()
    ControlThread()
    
    print('[QB-DOORLOCK] Client initialisé')
end)

-- Initialisation si le joueur est déjà connecté
Citizen.CreateThread(function()
    if QBCore.Functions.GetPlayerData() and QBCore.Functions.GetPlayerData().citizenid then
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
    end
end)

-- ================================
-- EXPORTS
-- ================================

-- Export pour toggle une porte
exports('ToggleLock', ToggleLock)

-- Export pour vérifier l'autorisation
exports('IsAuthorized', IsAuthorized)

-- Export pour obtenir l'état d'une porte
exports('GetDoorState', function(doorId)
    local door = doors[doorId]
    return door and door.locked or nil
end)

-- Export pour obtenir les portes proches
exports('GetNearbyDoors', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearbyDoors = {}
    
    for doorId, doorConfig in pairs(Config.Doors) do
        local distance = #(playerCoords - doorConfig.objCoords)
        if distance < 10.0 then
            table.insert(nearbyDoors, {
                id = doorId,
                distance = distance,
                locked = doors[doorId] and doors[doorId].locked or nil,
                authorized = IsAuthorized(doorId)
            })
        end
    end
    
    return nearbyDoors
end)

-- Export pour forcer l'état d'une porte (admin)
exports('SetDoorState', function(doorId, state)
    local door = doors[doorId]
    if door then
        door.locked = state
        FreezeEntityPosition(door.object, state)
        return true
    end
    return false
end)

-- ================================
-- COMMANDES DE DEBUG
-- ================================

-- Commande pour tester une porte
RegisterCommand('testdoor', function(source, args)
    if not args[1] then
        QBCore.Functions.Notify("Usage: /testdoor [doorId]", "error")
        return
    end
    
    local doorId = args[1]
    if Config.Doors[doorId] then
        ToggleLock(doorId)
    else
        QBCore.Functions.Notify("Porte introuvable: " .. doorId, "error")
    end
end, false)

-- Commande pour lister les portes proches
RegisterCommand('nearbydoors', function()
    local nearbyDoors = exports['qb-doorlock']:GetNearbyDoors()
    
    if #nearbyDoors == 0 then
        QBCore.Functions.Notify("Aucune porte à proximité", "primary")
        return
    end
    
    for _, door in ipairs(nearbyDoors) do
        local stateText = door.locked and "🔒" or "🔓"
        local authText = door.authorized and "✅" or "❌"
        local message = string.format("%s %s %s (%.1fm)", 
            stateText, authText, door.id, door.distance)
        TriggerEvent('chat:addMessage', {
            color = {100, 200, 100},
            args = {"PORTES", message}
        })
    end
end, false)

print('[QB-DOORLOCK] Module client principal chargé')
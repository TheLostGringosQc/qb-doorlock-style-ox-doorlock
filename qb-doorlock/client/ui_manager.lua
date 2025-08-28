-- ================================
-- UI MANAGER - QB-DOORLOCK
-- client/ui_manager.lua
-- Gestion avancée de l'interface utilisateur
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables UI
local UIManager = {}
local activeUI = nil
local uiCallbacks = {}
local uiAnimations = {}

-- ================================
-- SYSTÈME DE GESTION UI
-- ================================

-- Initialiser le gestionnaire UI
function UIManager.Initialize()
    -- Configurer NUI
    SetNuiFocus(false, false)
    
    -- Événements NUI
    RegisterNUICallback('closeUI', function(data, cb)
        UIManager.CloseUI()
        cb('ok')
    end)
    
    RegisterNUICallback('uiReady', function(data, cb)
        cb('ok')
    end)
    
    print('[UI-MANAGER] Gestionnaire d\'interface initialisé')
end

-- Ouvrir une interface spécifique
function UIManager.OpenUI(uiType, data, callback)
    if activeUI then
        UIManager.CloseUI()
    end
    
    activeUI = uiType
    uiCallbacks[uiType] = callback
    
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = 'showUI',
        uiType = uiType,
        data = data or {}
    })
    
    -- Animation d'ouverture
    UIManager.PlayAnimation('slideIn')
end

-- Fermer l'interface active
function UIManager.CloseUI()
    if not activeUI then return end
    
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        type = 'hideUI',
        uiType = activeUI
    })
    
    -- Callback de fermeture si défini
    if uiCallbacks[activeUI] then
        uiCallbacks[activeUI](nil)
        uiCallbacks[activeUI] = nil
    end
    
    activeUI = nil
    
    -- Animation de fermeture
    UIManager.PlayAnimation('slideOut')
end

-- Mettre à jour l'interface active
function UIManager.UpdateUI(data)
    if not activeUI then return end
    
    SendNUIMessage({
        type = 'updateUI',
        uiType = activeUI,
        data = data
    })
end

-- Jouer une animation UI
function UIManager.PlayAnimation(animType)
    if not uiAnimations[animType] then return end
    
    SendNUIMessage({
        type = 'playAnimation',
        animation = animType
    })
end

-- ================================
-- INTERFACES SPÉCIFIQUES
-- ================================

-- Interface de saisie de code
function UIManager.ShowCodeInput(doorId, doorLabel, callback)
    local data = {
        doorId = doorId,
        doorLabel = doorLabel or 'Porte sécurisée',
        title = 'Code d\'accès requis',
        placeholder = '••••',
        maxLength = 4
    }
    
    UIManager.OpenUI('codeInput', data, callback)
end

-- Interface de gestion de propriété (PS-Housing v2.0)
function UIManager.ShowPropertyManagement(propertyId, propertyData, callback)
    local data = {
        propertyId = propertyId,
        propertyData = propertyData,
        doors = exports['qb-doorlock']:getPropertyDoors(propertyId) or {},
        tenants = exports['qb-doorlock']:getPropertyTenants(propertyId) or {},
        managers = exports['qb-doorlock']:getPropertyManagers(propertyId) or {}
    }
    
    UIManager.OpenUI('propertyManagement', data, callback)
end

-- Interface d'alarme
function UIManager.ShowAlarmAlert(alarmData)
    local data = {
        doorId = alarmData.doorId,
        location = alarmData.location,
        alarmType = alarmData.alarmType,
        time = alarmData.time,
        severity = alarmData.severity or 'high'
    }
    
    UIManager.OpenUI('alarmAlert', data, function()
        -- Auto-fermeture après 10 secondes
        SetTimeout(10000, function()
            if activeUI == 'alarmAlert' then
                UIManager.CloseUI()
            end
        end)
    end)
end

-- Interface de sélection multiple (multi-clés)
function UIManager.ShowMultiKeySelection(doorId, requiredKeys, currentKeys, callback)
    local data = {
        doorId = doorId,
        requiredKeys = requiredKeys,
        currentKeys = currentKeys,
        progress = math.floor((#currentKeys / requiredKeys) * 100)
    }
    
    UIManager.OpenUI('multiKeySelection', data, callback)
end

-- Interface de statut des portes proches
function UIManager.ShowNearbyDoorsStatus(doors)
    local data = {
        doors = doors,
        playerJob = QBCore.Functions.GetPlayerData().job.name,
        timestamp = os.time()
    }
    
    UIManager.OpenUI('nearbyDoorsStatus', data)
end

-- Interface de maintenance
function UIManager.ShowMaintenancePanel(doorId, doorData, callback)
    local data = {
        doorId = doorId,
        doorData = doorData,
        maintenanceHistory = exports['qb-doorlock']:getMaintenanceHistory(doorId),
        currentIssues = exports['qb-doorlock']:getCurrentIssues(doorId)
    }
    
    UIManager.OpenUI('maintenancePanel', data, callback)
end

-- ================================
-- CALLBACKS NUI SPÉCIFIQUES
-- ================================

-- Callback pour code d'accès
RegisterNUICallback('submitCode', function(data, cb)
    if activeUI ~= 'codeInput' then
        cb('error')
        return
    end
    
    local callback = uiCallbacks['codeInput']
    if callback then
        callback(data.code)
    end
    
    UIManager.CloseUI()
    cb('ok')
end)

-- Callback pour gestion de propriété
RegisterNUICallback('propertyAction', function(data, cb)
    if activeUI ~= 'propertyManagement' then
        cb('error')
        return
    end
    
    local action = data.action
    local propertyId = data.propertyId
    
    if action == 'toggleDoor' then
        TriggerServerEvent('qb-doorlock:server:propertyInteraction', data.doorId, propertyId, data.doorType)
    elseif action == 'addTenant' then
        TriggerServerEvent('qb-doorlock:server:addTenant', propertyId, data.citizenid, data.permissions)
    elseif action == 'removeTenant' then
        TriggerServerEvent('qb-doorlock:server:removeTenant', propertyId, data.citizenid)
    elseif action == 'addManager' then
        TriggerServerEvent('qb-doorlock:server:addManager', propertyId, data.citizenid)
    end
    
    cb('ok')
end)

-- Callback pour multi-clés
RegisterNUICallback('multiKeyAction', function(data, cb)
    if activeUI ~= 'multiKeySelection' then
        cb('error')
        return
    end
    
    if data.action == 'useKey' then
        TriggerServerEvent('qb-doorlock:server:useMultiKey', data.doorId, data.keyType)
    elseif data.action == 'cancel' then
        UIManager.CloseUI()
    end
    
    cb('ok')
end)

-- Callback pour maintenance
RegisterNUICallback('maintenanceAction', function(data, cb)
    if activeUI ~= 'maintenancePanel' then
        cb('error')
        return
    end
    
    local action = data.action
    local doorId = data.doorId
    
    if action == 'repair' then
        TriggerServerEvent('qb-doorlock:server:repairDoor', doorId, data.repairType)
    elseif action == 'schedule' then
        TriggerServerEvent('qb-doorlock:server:scheduleMaintenance', doorId, data.scheduleData)
    elseif action == 'reportIssue' then
        TriggerServerEvent('qb-doorlock:server:reportIssue', doorId, data.issueDescription)
    end
    
    cb('ok')
end)

-- ================================
-- NOTIFICATIONS UI AVANCÉES
-- ================================

-- Notification personnalisée avec icône
function UIManager.ShowCustomNotification(message, type, duration, icon)
    SendNUIMessage({
        type = 'showNotification',
        message = message,
        notifyType = type or 'info',
        duration = duration or 3000,
        icon = icon
    })
end

-- Notification de porte avec état
function UIManager.ShowDoorNotification(doorId, state, doorType)
    local icons = {
        lock = 'fas fa-lock',
        unlock = 'fas fa-lock-open',
        alarm = 'fas fa-exclamation-triangle',
        maintenance = 'fas fa-tools',
        access_denied = 'fas fa-times-circle'
    }
    
    local colors = {
        lock = '#ff4444',
        unlock = '#44ff44',
        alarm = '#ff8800',
        maintenance = '#0088ff',
        access_denied = '#ff0000'
    }
    
    local messages = {
        lock = 'Porte verrouillée',
        unlock = 'Porte déverrouillée',
        alarm = 'Alarme déclenchée',
        maintenance = 'Maintenance requise',
        access_denied = 'Accès refusé'
    }
    
    SendNUIMessage({
        type = 'showDoorNotification',
        doorId = doorId,
        message = messages[state] or 'Action effectuée',
        icon = icons[state] or 'fas fa-door-closed',
        color = colors[state] or '#ffffff',
        doorType = doorType or 'standard'
    })
end

-- ================================
-- SYSTÈME D'AIDE CONTEXTUELLE
-- ================================

-- Afficher l'aide contextuelle
function UIManager.ShowContextualHelp(context, data)
    local helpData = {
        context = context,
        data = data,
        timestamp = os.time()
    }
    
    SendNUIMessage({
        type = 'showHelp',
        helpData = helpData
    })
end

-- Masquer l'aide contextuelle
function UIManager.HideContextualHelp()
    SendNUIMessage({
        type = 'hideHelp'
    })
end

-- ================================
-- GESTION DES THÈMES UI
-- ================================

-- Changer le thème de l'interface
function UIManager.SetTheme(themeName)
    SendNUIMessage({
        type = 'setTheme',
        theme = themeName
    })
end

-- Appliquer les paramètres personnalisés
function UIManager.ApplyCustomSettings(settings)
    SendNUIMessage({
        type = 'applySettings',
        settings = settings
    })
end

-- ================================
-- ÉVÉNEMENTS RÉSEAU UI
-- ================================

-- Mise à jour de l'état d'une porte
RegisterNetEvent('qb-doorlock:client:updateDoorUI')
AddEventHandler('qb-doorlock:client:updateDoorUI', function(doorId, state, doorData)
    UIManager.UpdateUI({
        type = 'doorUpdate',
        doorId = doorId,
        state = state,
        doorData = doorData
    })
    
    UIManager.ShowDoorNotification(doorId, state and 'lock' or 'unlock', doorData.doorType)
end)

-- Résultat de saisie de code
RegisterNetEvent('qb-doorlock:client:codeResult')
AddEventHandler('qb-doorlock:client:codeResult', function(success, doorId)
    if activeUI == 'codeInput' then
        UIManager.UpdateUI({
            type = 'codeResult',
            success = success,
            message = success and 'Code correct' or 'Code incorrect'
        })
        
        if success then
            SetTimeout(1000, function()
                UIManager.CloseUI()
            end)
        end
    end
end)

-- Alerte d'alarme
RegisterNetEvent('qb-doorlock:client:alarmAlert')
AddEventHandler('qb-doorlock:client:alarmAlert', function(alarmData)
    UIManager.ShowAlarmAlert(alarmData)
    
    -- Son d'alarme
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
end)

-- Mise à jour du statut multi-clés
RegisterNetEvent('qb-doorlock:client:multiKeyUpdate')
AddEventHandler('qb-doorlock:client:multiKeyUpdate', function(doorId, currentKeys, requiredKeys)
    if activeUI == 'multiKeySelection' then
        UIManager.UpdateUI({
            type = 'multiKeyUpdate',
            currentKeys = currentKeys,
            requiredKeys = requiredKeys,
            progress = math.floor((#currentKeys / requiredKeys) * 100)
        })
    end
end)

-- ================================
-- INITIALISATION
-- ================================

-- Initialiser au chargement du joueur
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    UIManager.Initialize()
end)

-- Thread de gestion UI
Citizen.CreateThread(function()
    while true do
        Wait(100)
        
        -- Vérifier si ESC est pressé pour fermer l'UI
        if activeUI and IsControlJustPressed(0, 322) then -- ESC
            UIManager.CloseUI()
        end
        
        -- Autres vérifications UI
        if activeUI then
            DisableControlAction(0, 1, true)   -- Look LR
            DisableControlAction(0, 2, true)   -- Look UD
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
        end
    end
end)

-- Exports pour autres ressources
exports('OpenUI', UIManager.OpenUI)
exports('CloseUI', UIManager.CloseUI)
exports('UpdateUI', UIManager.UpdateUI)
exports('ShowCodeInput', UIManager.ShowCodeInput)
exports('ShowPropertyManagement', UIManager.ShowPropertyManagement)
exports('ShowAlarmAlert', UIManager.ShowAlarmAlert)
exports('ShowMultiKeySelection', UIManager.ShowMultiKeySelection)
exports('ShowCustomNotification', UIManager.ShowCustomNotification)

print('[UI-MANAGER] Module UI Manager chargé')
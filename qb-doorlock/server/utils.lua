-- ================================
-- FICHIER server_utils.lua
-- ================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Utilitaires serveur pour QB-Doorlock
local DoorLockUtils = {}

-- Charger les états des portes depuis la base de données
function DoorLockUtils.LoadDoorStates()
    local result = MySQL.Sync.fetchAll('SELECT * FROM doorlocks')
    local states = {}
    
    for _, door in ipairs(result) do
        states[door.id] = door.locked == 1
    end
    
    return states
end

-- Sauvegarder l'état d'une porte
function DoorLockUtils.SaveDoorState(doorId, locked, citizenid)
    MySQL.Async.execute('INSERT INTO doorlocks (id, locked, last_user) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE locked = ?, last_user = ?', {
        doorId, locked and 1 or 0, citizenid, locked and 1 or 0, citizenid
    })
end

-- Logger l'activité
function DoorLockUtils.LogActivity(doorId, citizenid, action, job, grade)
    MySQL.Async.execute('INSERT INTO doorlock_logs (door_id, citizenid, action, job, grade) VALUES (?, ?, ?, ?, ?)', {
        doorId, citizenid, action, job, grade
    })
end

-- Obtenir les logs d'une porte
function DoorLockUtils.GetDoorLogs(doorId, limit)
    limit = limit or 50
    return MySQL.Sync.fetchAll('SELECT * FROM doorlock_logs WHERE door_id = ? ORDER BY timestamp DESC LIMIT ?', {doorId, limit})
end

-- Nettoyer les anciens logs (à exécuter périodiquement)
function DoorLockUtils.CleanOldLogs(days)
    days = days or 30
    MySQL.Async.execute('DELETE FROM doorlock_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL ? DAY)', {days})
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

-- Envoyer une notification Discord (optionnel)
function DoorLockUtils.SendDiscordLog(doorId, playerName, action, job)
    if not Config.DiscordWebhook then return end
    
    local embed = {
        {
            color = action == 'lock' and 16711680 or 65280, -- Rouge pour lock, vert pour unlock
            title = "🔐 Activité Porte",
            description = string.format("**Porte:** %s\n**Joueur:** %s\n**Action:** %s\n**Job:** %s\n**Heure:** %s",
                doorId,
                playerName,
                action == 'lock' and 'Verrouillée' or 'Déverrouillée',
                job,
                os.date("%d/%m/%Y %H:%M:%S")
            ),
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({embeds = embed}), {['Content-Type'] = 'application/json'})
end

-- Système de cooldown pour éviter le spam
local cooldowns = {}

function DoorLockUtils.IsOnCooldown(source, doorId)
    local key = source .. '_' .. doorId
    local now = GetGameTimer()
    
    if cooldowns[key] and (now - cooldowns[key]) < 2000 then -- 2 secondes de cooldown
        return true
    end
    
    cooldowns[key] = now
    return false
end

-- Export des utilitaires
exports('LoadDoorStates', DoorLockUtils.LoadDoorStates)
exports('SaveDoorState', DoorLockUtils.SaveDoorState)
exports('LogActivity', DoorLockUtils.LogActivity)
exports('GetDoorLogs', DoorLockUtils.GetDoorLogs)
exports('CleanOldLogs', DoorLockUtils.CleanOldLogs)
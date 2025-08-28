# 🔐 QB-Doorlock - Système de Verrouillage Avancé

Un système de verrouillage de portes complet pour QBCore, inspiré d'ox-doorlock avec intégrations ps-inventory et qb-target.

## 🚀 Fonctionnalités

### ✨ Principales
- **Système de jobs et grades** - Contrôle d'accès basé sur l'emploi et le niveau
- **Intégration ps-inventory** - Items requis avec option de consommation
- **Support qb-target** - Interaction moderne avec icônes personnalisées
- **Codes d'accès** - Interface NUI pour saisir des codes de sécurité
- **Horaires automatiques** - Ouverture/fermeture programmée
- **Groupes de portes** - Contrôle multiple simultané
- **Base de données** - Sauvegarde persistante des états

### 🎯 Interface utilisateur
- **Texte 3D** avec état visuel (🔒/🔓)
- **Interface NUI moderne** pour les codes d'accès
- **Notifications détaillées** avec raisons d'échec
- **Animations** fluides lors des interactions
- **Sons** de verrouillage/déverrouillage

### 📊 Administration
- **Logs complets** de toutes les activités
- **Commandes admin** pour forcer les états
- **Discord webhook** (optionnel)
- **Nettoyage automatique** des anciens logs

## 📁 Structure des fichiers

```
qb-doorlock/
├── fxmanifest.lua          # Manifest principal
├── config.lua              # Configuration des portes
├── client.lua              # Script client principal
├── client_advanced.lua     # Fonctionnalités avancées client
├── server.lua              # Script serveur principal  
├── server_utils.lua        # Utilitaires serveur
├── html/
│   └── index.html          # Interface NUI
└── sql/
    └── doorlock.sql        # Structure base de données
```

## 🛠️ Installation

### 1. Prérequis
- QBCore Framework
- qb-target
- ps-inventory
- MySQL/MariaDB

### 2. Installation des fichiers
```bash
# Copier dans le dossier resources
cp -r qb-doorlock [qb]/qb-doorlock

# Ajouter dans server.cfg
ensure qb-doorlock
```

### 3. Base de données
```sql
-- Exécuter le fichier SQL fourni
source sql/doorlock.sql
```

### 4. Items (qb-core/shared/items.lua)
```lua
-- Ajouter les items fournis dans la documentation
['police_keycard'] = { ... },
['hospital_keycard'] = { ... },
-- etc.
```

## ⚙️ Configuration

### Configuration d'une porte basique
```lua
['ma_porte'] = {
    objName = 'v_ilev_ph_door01',                    -- Nom du modèle
    objCoords = vector3(434.7479, -980.6187, 30.8896), -- Position
    textCoords = vector3(434.7479, -981.6187, 31.8896), -- Texte 3D
    authorizedJobs = {'police'},                      -- Jobs autorisés
    locked = true,                                    -- État initial
    distance = 2.5,                                   -- Distance interaction
    targetOptions = {                                 -- Options qb-target
        {
            type = "client",
            event = "qb-doorlock:client:toggleLock",
            icon = "fas fa-lock",
            label = "Verrouiller/Déverrouiller"
        }
    }
}
```

### Configuration avancée avec items
```lua
['porte_securisee'] = {
    objName = 'prop_door_secure',
    objCoords = vector3(100.0, 200.0, 30.0),
    textCoords = vector3(100.0, 201.0, 31.0),
    authorizedJobs = {'police', 'fbi'},
    authorizedGrades = {2, 3, 4},                    -- Grades minimum
    locked = true,
    distance = 2.0,
    requiredItems = {                                -- Items requis
        {item = 'security_keycard', remove = false}, -- Ne retire pas
        {item = 'access_code', remove = true}        -- Retire après usage
    },
    notifications = {                                -- Messages personnalisés
        success = "Accès autorisé",
        fail = "Sécurité activée",
        unauthorized = "Accès refusé"
    }
}
```

### Configuration avec code d'accès
```lua
['coffre_banque'] = {
    objName = 'prop_vault_door',
    objCoords = vector3(250.0, 300.0, 25.0),
    textCoords = vector3(250.0, 301.0, 26.0),
    authorizedJobs = {'police'},
    locked = true,
    requiresCode = true,                             -- Nécessite un code
    securityCode = "1234",                          -- Code à saisir
    targetOptions = {
        {
            type = "client",
            event = "qb-doorlock:client:requestCode",
            icon = "fas fa-keyboard",
            label = "Saisir le code"
        }
    }
}
```

### Horaires automatiques
```lua
['garage_mechanic'] = {
    -- ... autres configs
    schedule = {
        openHour = 8,                               -- Ouvre à 8h
        closeHour = 22,                            -- Ferme à 22h
        allowAfterHours = false                    -- Bloque hors horaires
    }
}
```

### Groupes de portes
```lua
Config.DoorGroups = {
    ['cellules_police'] = {
        doors = {'cellule_1', 'cellule_2', 'cellule_3'},
        authorizedJobs = {'police'},
        requiredGrade = 3                          -- Sergent et plus
    }
}
```

## 🎮 Utilisation

### Pour les joueurs
- **Approchez-vous** d'une porte configurée
- **Regardez le texte 3D** pour voir l'état (🔒/🔓)
- **Utilisez qb-target** ou **appuyez sur E** pour interagir
- **Saisissez le code** si demandé via l'interface NUI

### Commandes admin
```lua
/adoorlock [doorId] [true/false]  -- Forcer l'état d'une porte
/doorlogs [doorId]                -- Voir les logs d'une porte
/reloaddoors                      -- Recharger la configuration
/cleandoorlogs [days]             -- Nettoyer les anciens logs
```

## 🔧 API et Exports

### Client
```lua
-- Toggle une porte
exports['qb-doorlock']:ToggleLock(doorId)

-- Vérifier l'autorisation
local authorized = exports['qb-doorlock']:IsAuthorized(doorId)

-- Obtenir l'état d'une porte
local isLocked = exports['qb-doorlock']:GetDoorState(doorId)

-- Obtenir les portes proches
local nearbyDoors = exports['qb-doorlock']:GetNearbyDoors()

-- Toggle un groupe de portes
exports['qb-doorlock']:ToggleDoorGroup(groupId)
```

### Serveur
```lua
-- Définir l'état d'une porte
local success = exports['qb-doorlock']:SetDoorState(doorId, locked)

-- Obtenir l'état d'une porte
local isLocked = exports['qb-doorlock']:GetDoorState(doorId)

-- Obtenir les logs d'une porte
local logs = exports['qb-doorlock']:GetDoorLogs(doorId, limit)

-- Nettoyer les anciens logs
exports['qb-doorlock']:CleanOldLogs(days)
```

## 🎨 Personnalisation

### Interface NUI
L'interface est entièrement personnalisable via le fichier `html/index.html`. Vous pouvez :
- Modifier les couleurs et animations CSS
- Changer la disposition des éléments
- Ajouter de nouveaux effets visuels
- Personnaliser les sons et vibrations

### Sons
```lua
Config.Sounds = {
    lock = "Door_Close",      -- Son de verrouillage
    unlock = "Door_Open"      -- Son de déverrouillage
}
```

### Messages
```lua
Config.Locales = {
    ['door_locked'] = 'Porte verrouillée',
    ['door_unlocked'] = 'Porte déverrouillée',
    ['no_authorization'] = 'Vous n\'avez pas l\'autorisation',
    -- Personnalisable selon vos besoins
}
```

## 📊 Base de données

### Tables créées
- **doorlocks** - États des portes
- **doorlock_logs** - Historique des activités

### Nettoyage automatique
- Les logs sont automatiquement nettoyés chaque semaine
- Conservation par défaut : 30 jours
- Configurable via commandes admin

## 🔒 Sécurité

### Vérifications serveur
- Tous les accès sont vérifiés côté serveur
- Anti-spam avec système de cooldown
- Logs détaillés de toutes les activités
- Vérification des items en temps réel

### Protection contre les exploits
- Vérification de distance
- Validation des paramètres
- Prévention des requêtes malveillantes

## 🆘 Dépannage

### Problèmes courants

**Les portes ne se chargent pas :**
- Vérifiez que les coordonnées sont correctes
- Assurez-vous que les modèles existent sur la map
- Redémarrez la ressource avec `/restart qb-doorlock`

**L'interface NUI ne s'affiche pas :**
- Vérifiez la console F8 pour les erreurs JavaScript
- Assurez-vous que NUI n'est pas désactivé
- Testez avec `/lua ExecuteCommand('quit')` puis reconnectez-vous

**Les items ne sont pas détectés :**
- Vérifiez que ps-inventory est démarré avant qb-doorlock
- Confirmez que les items existent dans la base de données
- Testez avec `/giveitem [item] 1`

### Debug
Activez le debug dans config.lua :
```lua
Config.Debug = true  -- Affiche les informations de debug
```

## 🤝 Support

Pour obtenir de l'aide :
1. Consultez cette documentation
2. Vérifiez les logs serveur et console F8
3. Testez avec une configuration minimale
4. Contactez le support technique

## 📄 Licence

Ce script est fourni "tel quel" sans garantie. Libre d'utilisation et modification pour usage privé.

---

*Développé avec ❤️ pour la communauté QBCore*

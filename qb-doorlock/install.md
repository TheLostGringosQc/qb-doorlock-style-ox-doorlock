# 🚪🔐 QB-Doorlock - Guide d'Installation

Guide d'installation complet pour QB-Doorlock avec intégration PS-Housing v1.x et v2.0.x

## 📋 Prérequis

### **Ressources requises**
- ✅ **QBCore Framework** (dernière version)
- ✅ **qb-target** (système d'interaction)
- ✅ **ps-inventory** (gestion des items)
- ✅ **oxmysql** (base de données)

### **Ressources optionnelles**
- 🏠 **ps-housing** (v1.x ou v2.0.x) - Pour les maisons/propriétés
- 🎮 **qb-gangs** - Pour le système de territoires
- 🌤️ **qb-weathersync** - Pour les effets météo
- 📱 **qb-phone** - Pour les notifications

## 📁 Structure des fichiers

Créez cette structure dans votre dossier `[qb]/qb-doorlock/` :

```
qb-doorlock/
├── fxmanifest.lua                      # Manifest principal
├── config.lua                          # Configuration
├──
├── client/
│   ├── main.lua                        # [VOTRE FICHIER EXISTANT]
│   ├── pshousing_integration.lua       # PS-Housing v1.x client
│   ├── pshousing_v2_integration.lua    # PS-Housing v2.0.x client
│   └── ui_manager.lua                  # Gestionnaire d'interface
├──
├── server/
│   ├── main.lua                        # [VOTRE FICHIER EXISTANT]
│   ├── pshousing_integration.lua       # PS-Housing v1.x serveur
│   ├── pshousing_v2_integration.lua    # PS-Housing v2.0.x serveur
│   ├── advanced_systems.lua           # Systèmes avancés
│   └── migration.lua                   # Migration automatique
├──
├── html/
│   ├── index.html                      # Interface NUI principale
│   ├── style.css                       # Styles CSS
│   ├── script.js                       # JavaScript NUI
│   └── assets/                         # Images et sons
│       ├── police_keycard.png
│       ├── house_key.png
│       └── ...
├──
├── sql/
│   ├── migration_v2.sql                # Migration base de données
│   └── items.sql                       # Items à ajouter
├──
├── tests/
│   └── pshousing_v2_compatibility.lua  # Tests de compatibilité
└──
└── README.md                           # Documentation
```

## 🚀 Installation étape par étape

### **Étape 1 : Préparation**

```bash
# 1. Arrêter le serveur ou la ressource existante
stop qb-doorlock

# 2. Sauvegarder votre version actuelle (si existante)
cp -r qb-doorlock qb-doorlock-backup-$(date +%Y%m%d)

# 3. Sauvegarder la base de données (si existante)
mysqldump -u username -p database_name doorlocks doorlock_logs > qb_doorlock_backup.sql
```

### **Étape 2 : Installation des fichiers**

1. **Copier tous les nouveaux fichiers** fournis dans le dossier `qb-doorlock/`

2. **Remplacer** les fichiers principaux :
   - `config.lua` → Version étendue
   - `fxmanifest.lua` → Nouvelles dépendances

3. **Conserver** vos fichiers existants :
   - `client/main.lua` → Votre script client existant
   - `server/main.lua` → Votre script serveur existant

### **Étape 3 : Base de données**

```sql
-- Se connecter à votre base de données MySQL
mysql -u username -p database_name

-- Exécuter le script de migration
SOURCE sql/migration_v2.sql;

-- Optionnel : Ajouter les items directement en base
SOURCE sql/items.sql;
```

### **Étape 4 : Configuration des items**

**Option A : Via qb-core/shared/items.lua** (recommandé)

```lua
-- Dans qb-core/shared/items.lua, ajouter :

-- Items police
['police_keycard'] = {
    ['name'] = 'police_keycard',
    ['label'] = 'Badge Police',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'police_keycard.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['description'] = 'Badge d\'accès pour le commissariat'
},

['police_keys'] = {
    ['name'] = 'police_keys',
    ['label'] = 'Clés des Cellules',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'police_keys.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['description'] = 'Trousseau de clés pour les cellules'
},

-- Items médical
['hospital_keycard'] = {
    ['name'] = 'hospital_keycard',
    ['label'] = 'Badge Médical',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'hospital_keycard.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['description'] = 'Badge d\'accès hospitalier'
},

-- Items maisons/propriétés
['house_key_template'] = {
    ['name'] = 'house_key_template',
    ['label'] = 'Clé de Maison',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'house_key.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['description'] = 'Clé d\'une maison privée'
},

['property_key_template'] = {
    ['name'] = 'property_key_template',
    ['label'] = 'Clé de Propriété',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'property_key.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['description'] = 'Clé d\'une propriété'
},

-- Outils spécialisés
['key_duplication_kit'] = {
    ['name'] = 'key_duplication_kit',
    ['label'] = 'Kit de Duplication',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'key_duplication_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Permet de dupliquer des clés'
},

['master_key'] = {
    ['name'] = 'master_key',
    ['label'] = 'Passe-Partout',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'master_key.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = false,
    ['description'] = 'Clé universelle pour agent immobilier'
},

-- Items de sécurité avancée
['bank_card'] = {
    ['name'] = 'bank_card',
    ['label'] = 'Carte Bancaire Sécurisée',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'bank_card.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Carte d\'accès au coffre-fort - Usage unique'
},

['security_code'] = {
    ['name'] = 'security_code',
    ['label'] = 'Code de Sécurité',
    ['weight'] = 10,
    ['type'] = 'item',
    ['image'] = 'security_code.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Code d\'accès temporaire'
}
```

**Option B : Utiliser le SQL fourni** (items.sql)

Si vous préférez ajouter les items directement en base de données, le fichier `sql/items.sql` contient tout le nécessaire.

### **Étape 5 : Configuration**

Éditez le fichier `config.lua` selon vos besoins :

```lua
-- Configuration de base
Config.UseTarget = true              -- true si vous utilisez qb-target
Config.Use3DText = true              -- Affichage texte 3D
Config.Debug = false                 -- Mode debug (false en production)

-- PS-Housing v1.x (si vous l'utilisez)
Config.PSHousing = {
    Enabled = true,                  -- true si PS-Housing v1.x
    AutoCreateDoors = true,          -- Créer portes automatiquement
    KeyItemPrefix = 'house_key_',    -- Préfixe des clés v1.x
}

-- PS-Housing v2.0.x (si vous l'utilisez)
Config.PSHousingV2 = {
    Enabled = true,                  -- true si PS-Housing v2.0.x
    AutoDetectVersion = true,        -- Détection automatique
    SupportMultipleDoors = true,     -- Portes multiples par propriété
    -- ... autres options
}

-- Systèmes avancés (optionnels)
Config.AlarmSystem = {
    enabled = true,                  -- Système d'alarmes
    cooldownTime = 300,              -- 5 minutes entre alarmes
}

Config.Maintenance = {
    enabled = true,                  -- Système de maintenance
    allowedJobs = {'mechanic'},      -- Jobs autorisés
    repairCost = 250,               -- Coût de réparation
}
```

### **Étape 6 : Images des items**

Placez les images des items dans le dossier de ps-inventory :

```bash
# Copier les images vers ps-inventory
cp html/assets/*.png [ps]/ps-inventory/html/images/
```

Images nécessaires :
- `police_keycard.png`
- `police_keys.png`
- `hospital_keycard.png`
- `house_key.png`
- `property_key.png`
- `key_duplication_kit.png`
- `master_key.png`
- `bank_card.png`
- `security_code.png`

### **Étape 7 : Configuration serveur**

Dans votre `server.cfg`, assurez-vous de l'ordre de chargement :

```cfg
# Dépendances principales
ensure qb-core
ensure oxmysql
ensure ps-inventory
ensure qb-target

# PS-Housing (si utilisé)
ensure ps-housing

# QB-Doorlock (TOUJOURS EN DERNIER)
ensure qb-doorlock
```

### **Étape 8 : Démarrage et tests**

```bash
# 1. Redémarrer le serveur ou la ressource
restart qb-doorlock

# 2. Vérifier les logs pour des erreurs
# Dans la console serveur, chercher des erreurs

# 3. Tests de base
/doorlockversion          # Vérifier la version installée
/doorstats               # Statistiques générales

# 4. Tests PS-Housing (si utilisé)
/pshousinginfo           # Informations intégration
/testpshousingv2         # Tests de compatibilité (v2.0.x)
```

## ⚙️ Configuration par cas d'usage

### **Cas 1 : Serveur basique (sans PS-Housing)**

```lua
-- config.lua
Config.PSHousing.Enabled = false
Config.PSHousingV2.Enabled = false
Config.AlarmSystem.enabled = true      -- Garder les alarmes
Config.Maintenance.enabled = true      -- Garder la maintenance

-- fxmanifest.lua - Retirer les scripts PS-Housing
server_scripts {
    'server/main.lua',
    'server/advanced_systems.lua',     -- Garder
    'server/migration.lua',            -- Garder
    -- Ne pas inclure pshousing_*.lua
}
```

### **Cas 2 : Avec PS-Housing v1.x**

```lua
-- config.lua
Config.PSHousing.Enabled = true
Config.PSHousingV2.Enabled = false
Config.PSHousingV2.AutoDetectVersion = true  -- Détection auto

-- Garder tous les scripts dans fxmanifest.lua
```

### **Cas 3 : Avec PS-Housing v2.0.x**

```lua
-- config.lua
Config.PSHousing.Enabled = true          -- Rétrocompatibilité
Config.PSHousingV2.Enabled = true        -- Nouvelles fonctionnalités
Config.PSHousingV2.SupportMultipleDoors = true
Config.PSHousingV2.PropertyTypes = {
    'house', 'apartment', 'office', 'warehouse', 'garage', 'shop'
}

-- Utiliser tous les scripts dans fxmanifest.lua
```

### **Cas 4 : Serveur haute performance**

```lua
-- config.lua - Optimisations
Config.UpdateRate = 2000              -- Moins fréquent
Config.MaxDistance = 2.0              -- Distance réduite
Config.AlarmSystem.cooldownTime = 600 -- Cooldown plus long
Config.Testing.enableAutoTests = false
Config.Debug = false

-- Désactiver les fonctionnalités non utilisées
Config.Maintenance.enabled = false   -- Si pas de mécaniciens
```

## 🔍 Vérifications post-installation

### **Tests de fonctionnement**

```lua
-- 1. Portes standards
/adoorlock lspd_main_entrance true
/doorlogs lspd_main_entrance

-- 2. Interface NUI (si porte avec code)
-- Approchez-vous d'une porte avec requiresCode = true

-- 3. PS-Housing (si utilisé)
-- Acheter une maison via ps-housing
-- Vérifier qu'une porte est créée automatiquement

-- 4. Systèmes avancés
/activealarms                         -- Alarmes actives
/testalarm lspd_main_entrance test    -- Test alarme

-- 5. Migration (si applicable)
/migrationhistory                     -- Historique des migrations
/doorlockversion                      -- Version et statut
```

### **Vérifications visuelles**

- [ ] **Texte 3D** s'affiche au-dessus des portes (🔒/🔓)
- [ ] **qb-target** fonctionne avec les icônes appropriées  
- [ ] **Interface NUI** s'ouvre pour les codes d'accès
- [ ] **Notifications** s'affichent correctement
- [ ] **Animations** de verrouillage/déverrouillage
- [ ] **Sons** lors des interactions

### **Vérifications base de données**

```sql
-- Vérifier les tables créées
SHOW TABLES LIKE 'doorlock%';

-- Résultat attendu :
-- doorlocks
-- doorlock_logs  
-- doorlock_security_logs
-- doorlock_maintenance
-- doorlock_property_keys (si PS-Housing v2.0)

-- Vérifier quelques données
SELECT COUNT(*) FROM doorlocks;
SELECT COUNT(*) FROM doorlock_logs WHERE timestamp > DATE_SUB(NOW(), INTERVAL 1 DAY);
```

## 🆘 Résolution de problèmes

### **Problème : Ressource ne démarre pas**

**Symptômes :** Erreurs dans la console serveur

**Solutions :**
```bash
# 1. Vérifier les dépendances
ensure qb-core      # AVANT qb-doorlock
ensure ps-inventory # AVANT qb-doorlock
ensure qb-target    # AVANT qb-doorlock

# 2. Vérifier la syntaxe Lua
lua -c fxmanifest.lua
lua -c config.lua

# 3. Logs détaillés
setr qb-doorlock:debug true
restart qb-doorlock
```

### **Problème : Portes ne répondent pas**

**Symptômes :** Pas d'interaction, pas de texte 3D

**Solutions :**
```lua
-- 1. Vérifier les coordonnées dans config.lua
-- Les coordonnées doivent être exactes

-- 2. Vérifier qb-target
/qbtarget  -- Commande de debug qb-target

-- 3. Test basique
/adoorlock test_door true  -- Forcer un état
```

### **Problème : PS-Housing non détecté**

**Symptômes :** `/pshousinginfo` montre "Non détectée"

**Solutions :**
```cfg
# 1. Vérifier l'ordre dans server.cfg
ensure ps-housing     # AVANT qb-doorlock
ensure qb-doorlock    # APRÈS ps-housing

# 2. Vérifier la version PS-Housing
# Dans ps-housing/fxmanifest.lua chercher la version

# 3. Test manuel
/testpshousingv2     # Lancer les tests de compatibilité
```

### **Problème : Interface NUI ne s'affiche pas**

**Symptômes :** Pas d'interface pour saisir les codes

**Solutions :**
```bash
# 1. Vérifier les fichiers NUI
ls -la html/
# Doit contenir : index.html, style.css, script.js

# 2. Console F8 (côté client)
# Chercher des erreurs JavaScript

# 3. Test de la NUI
# Dans config.lua, ajouter une porte avec :
requiresCode = true
securityCode = "1234"
```

### **Problème : Items non trouvés**

**Symptômes :** Erreurs "Item not found"

**Solutions :**
```sql
-- 1. Vérifier les items en base
SELECT name FROM items WHERE name LIKE '%key%' OR name LIKE '%card%';

-- 2. Ou dans qb-core/shared/items.lua
-- Chercher les items ajoutés

-- 3. Restart qb-core après ajout d'items
restart qb-core
restart ps-inventory
restart qb-doorlock
```

### **Problème : Performance dégradée**

**Symptômes :** Lag, FPS bas

**Solutions :**
```lua
-- Dans config.lua, optimiser :
Config.UpdateRate = 2000        -- Plus lent
Config.MaxDistance = 2.0        -- Distance réduite
Config.Use3DText = false        -- Désactiver si problème
Config.Testing.enableAutoTests = false
Config.AlarmSystem.cooldownTime = 600

-- Désactiver fonctionnalités non utilisées
Config.PSHousing.Enabled = false       -- Si pas de PS-Housing
Config.Maintenance.enabled = false     -- Si pas besoin
```

## 🔧 Maintenance et mises à jour

### **Sauvegarde régulière**

```bash
# Script de sauvegarde (à exécuter régulièrement)
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)

# Sauvegarder les fichiers
cp -r qb-doorlock qb-doorlock-backup-$DATE

# Sauvegarder la base de données
mysqldump -u username -p database_name doorlocks doorlock_logs doorlock_security_logs doorlock_maintenance > qb-doorlock-db-$DATE.sql

echo "Sauvegarde terminée: $DATE"
```

### **Nettoyage automatique**

```sql
-- Nettoyer les anciens logs (à exécuter mensuellement)
CALL CleanupOldLogs(30);  -- Garder 30 jours

-- Ou manuellement
DELETE FROM doorlock_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);
DELETE FROM doorlock_security_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY) AND resolved = 1;
```

### **Monitoring**

```lua
-- Commandes de surveillance
/doorstats           -- Statistiques générales
/activealarms        -- Alarmes en cours
/migrationhistory    -- Historique des mises à jour

-- Logs à surveiller
tail -f logs/server.log | grep "QB-DOORLOCK"
```

## 📊 Optimisation avancée

### **Pour serveurs haute population (200+ joueurs)**

```lua
-- config.lua
Config.UpdateRate = 3000
Config.MaxDistance = 2.0
Config.AlarmSystem.cooldownTime = 900  -- 15 minutes
Config.Testing.enableAutoTests = false

-- Désactiver certaines fonctionnalités
Config.Use3DText = false  -- Utiliser seulement qb-target
Config.Maintenance.enabled = false
```

### **Pour serveurs RP immersifs**

```lua
-- config.lua - Fonctionnalités complètes
Config.UpdateRate = 500
Config.MaxDistance = 3.0
Config.Use3DText = true
Config.AlarmSystem.enabled = true
Config.Maintenance.enabled = true
Config.PSHousingV2.SupportMultipleDoors = true

-- Sons et animations
Config.Sounds = {
    lock = "Door_Close",
    unlock = "Door_Open"
}
```

## 🎮 Formation des administrateurs

### **Commandes essentielles pour les admins**

```lua
-- Gestion basique
/adoorlock [doorId] [true/false]      -- Forcer l'état d'une porte
/doorlogs [doorId]                    -- Voir les logs d'une porte
/reloaddoors                          -- Recharger la configuration

-- Diagnostic
/doorstats                            -- Statistiques générales  
/doorlockversion                      -- Version et infos système
/pshousinginfo                        -- État intégration PS-Housing

-- Urgence
/emergencyunlock [job]                -- Déverrouiller toutes les portes d'un job
/testalarm [doorId] [type]            -- Déclencher une alarme de test

-- Maintenance
/cleandoorlogs [days]                 -- Nettoyer les anciens logs
/forcemigration [version]             -- Forcer une migration
```

### **Procédures d'urgence**

**En cas de problème majeur :**

1. **Déverrouillage d'urgence**
```lua
/emergencyunlock police    -- Toutes les portes police
/emergencyunlock ambulance -- Toutes les portes hôpital
```

2. **Redémarrage propre**
```bash
stop qb-doorlock
# Attendre 5 secondes
start qb-doorlock
```

3. **Restauration depuis sauvegarde**
```bash
stop qb-doorlock
cp -r qb-doorlock-backup-[DATE] qb-doorlock
mysql -u username -p database_name < qb-doorlock-db-[DATE].sql
start qb-doorlock
```

## 📈 Métriques et surveillance

### **KPI à surveiller**

- **Nombre d'interactions** par jour (doorlock_logs)
- **Taux d'échec** des accès (access_denied dans security_logs)
- **Nombre d'alarmes** déclenchées par jour
- **Performance** (temps de réponse < 100ms)
- **Erreurs** dans les logs serveur

### **Dashboard recommandé**

```sql
-- Requête pour dashboard admin
SELECT 
    'Interactions 24h' as metric,
    COUNT(*) as value
FROM doorlock_logs 
WHERE timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR)

UNION ALL

SELECT 
    'Alarmes actives' as metric,
    COUNT(*) as value  
FROM doorlock_security_logs 
WHERE event_type = 'alarm' 
AND timestamp > DATE_SUB(NOW(), INTERVAL 1 HOUR)

UNION ALL

SELECT 
    'Accès refusés 24h' as metric,
    COUNT(*) as value
FROM doorlock_security_logs
WHERE event_type = 'access_denied'
AND timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR);
```

## ✅ Checklist finale

### **Avant la mise en production**

- [ ] **Toutes les dépendances** installées et fonctionnelles
- [ ] **Base de données** migrée et vérifiée
- [ ] **Items** ajoutés dans qb-core ou en base
- [ ] **Images** des items copiées dans ps-inventory
- [ ] **Configuration** adaptée à votre serveur
- [ ] **PS-Housing** intégré (si utilisé)
- [ ] **Tests complets** effectués sur serveur de test
- [ ] **Équipe d'administration** formée
- [ ] **Procédures d'urgence** documentées
- [ ] **Sauvegarde initiale** effectuée

### **Post-déploiement (première semaine)**

- [ ] **Monitoring** des performances
- [ ] **Feedback** des joueurs collecté
- [ ] **Logs d'erreurs** surveillés quotidiennement
- [ ] **Ajustements** de configuration si nécessaire
- [ ] **Formation** des modérateurs/admins

---

## 🎉 Félicitations !

Votre installation de **QB-Doorlock** est maintenant terminée ! 

Vous disposez d'un système de portes moderne avec :
- 🏠 **Intégration PS-Housing** complète (v1.x et v2.0.x)
- 🚨 **Systèmes d'alarmes** et de sécurité avancés
- 🔧 **Maintenance automatique** et logs détaillés
- 🎮 **Interface utilisateur** moderne avec NUI
- 📊 **Monitoring** et statistiques complètes

**Support :** Pour toute question, consultez les logs, utilisez les commandes de diagnostic, et n'hésitez pas à demander de l'aide sur le Discord QBCore.

**Bon jeu ! 🎮✨**
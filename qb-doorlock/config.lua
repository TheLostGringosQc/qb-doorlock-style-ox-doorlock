-- ================================
-- CONFIG.LUA FINAL - QB-DOORLOCK
-- Intégration complète PS-Housing v1.x et v2.0.x
-- ================================

Config = {}

-- ================================
-- CONFIGURATION GÉNÉRALE
-- ================================

Config.UpdateRate = 1000          -- Taux de rafraîchissement en ms
Config.MaxDistance = 2.5          -- Distance maximum pour interagir
Config.UseTarget = true           -- Utiliser qb-target
Config.Use3DText = true           -- Afficher le texte 3D
Config.UseKeyPress = true         -- Permettre l'interaction avec E
Config.Debug = false              -- Mode debug (dev uniquement)

-- Sons
Config.Sounds = {
    lock = "Door_Close",
    unlock = "Door_Open"
}

-- Discord webhook pour les logs (optionnel)
Config.DiscordWebhook = nil -- "https://discord.com/api/webhooks/..."

-- ================================
-- INTÉGRATION PS-HOUSING
-- ================================

-- Configuration PS-Housing v1.x (rétrocompatibilité)
Config.PSHousing = {
    Enabled = true,                 -- Activer l'intégration v1.x
    AutoCreateDoors = true,         -- Créer automatiquement les portes
    DefaultLocked = true,           -- État par défaut des portes
    UseHouseKeys = true,            -- Utiliser le système de clés
    AllowRealtor = true,            -- Permettre aux agents immobiliers
    KeyItemPrefix = 'house_key_',   -- Préfixe des items de clés v1.x
}

-- Configuration PS-Housing v2.0.x (nouvelle version)
Config.PSHousingV2 = {
    Enabled = true,                 -- Activer l'intégration v2.0
    Version = "2.0.x",
    AutoDetectVersion = true,       -- Détecter automatiquement la version
    
    -- Nouvelles fonctionnalités v2.0
    SupportMultipleDoors = true,    -- Support des portes multiples
    SupportGarages = true,          -- Support des garages
    SupportBasements = true,        -- Support des sous-sols
    AutoSyncWithMLO = true,         -- Synchronisation avec les MLO
    UseNewEventSystem = true,       -- Utiliser les nouveaux events v2.0
    
    -- Mapping des types de propriétés v2.0
    PropertyTypes = {
        ['house'] = 'house',
        ['apartment'] = 'apartment',
        ['mansion'] = 'mansion',
        ['office'] = 'office',         -- Nouveau v2.0
        ['warehouse'] = 'warehouse',   -- Nouveau v2.0
        ['garage'] = 'garage',         -- Nouveau v2.0
        ['shop'] = 'shop'              -- Nouveau v2.0
    },
    
    -- Modèles de portes par type de propriété
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
    },
    
    -- Préfixes des clés selon le type v2.0
    KeyPrefixes = {
        owner = 'property_key_',
        tenant = 'property_key_',
        manager = 'property_key_',
        temporary = 'temp_key_'
    }
}

-- Configuration avancée pour les maisons
Config.HouseIntegration = {
    -- Types de portes par défaut
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
        keyPrefix = 'house_key_',               -- v1.x
        propertyKeyPrefix = 'property_key_',    -- v2.0
        defaultTempDuration = 3600,             -- 1 heure
        realtorAccess = true,
        keyMakers = {'realestate', 'mechanic'},
    },
    
    -- Notifications spéciales pour les maisons
    Notifications = {
        houseUnlocked = "🏠 Maison déverrouillée",
        houseLocked = "🏠 Maison verrouillée",
        propertyUnlocked = "🏢 Propriété déverrouillée",    -- v2.0
        propertyLocked = "🏢 Propriété verrouillée",        -- v2.0
        keyReceived = "🔑 Vous avez reçu une clé",
        keyRemoved = "🔑 Votre clé a été retirée",
        accessDenied = "🚫 Vous n'avez pas la clé",
        tempKeyExpired = "⏰ Votre clé temporaire a expiré",
        tenantAccess = "🏠 Accès locataire accordé",        -- v2.0
        managerAccess = "👔 Accès gestionnaire accordé"     -- v2.0
    }
}

-- ================================
-- CONFIGURATION DES PORTES STANDARD
-- ================================

Config.Doors = {
    -- ===================
    -- COMMISSARIAT LSPD
    -- ===================
    ['lspd_main_entrance'] = {
        objName = 'v_ilev_ph_door01',
        objCoords = vector3(434.7479, -980.6187, 30.8896),
        textCoords = vector3(434.7479, -981.6187, 31.8896),
        authorizedJobs = {'police'},
        locked = true,
        distance = 2.5,
        size = 2.0,
        requiredItems = {
            {item = 'police_keycard', remove = false},
        },
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:toggleLock",
                icon = "fas fa-lock",
                label = "Accès Commissariat",
                job = {'police'}
            }
        }
    },
    
    ['lspd_cells_main'] = {
        objName = 'v_ilev_ph_cellgate',
        objCoords = vector3(463.4782, -992.6641, 24.9149),
        textCoords = vector3(463.4782, -993.6641, 25.9149),
        authorizedJobs = {'police'},
        locked = true,
        distance = 1.5,
        size = 1.5,
        requiredItems = {
            {item = 'police_keys', remove = false},
        },
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:toggleLock",
                icon = "fas fa-key",
                label = "Ouvrir/Fermer cellule",
                job = {'police'}
            }
        }
    },
    
    ['lspd_evidence'] = {
        objName = 'v_ilev_ph_door02',
        objCoords = vector3(471.3154, -985.0448, 24.9149),
        textCoords = vector3(471.3154, -986.0448, 25.9149),
        authorizedJobs = {'police'},
        authorizedGrades = {3, 4}, -- Sergent et plus
        locked = true,
        distance = 2.0,
        size = 2.0,
        requiredItems = {
            {item = 'evidence_keycard', remove = false},
        },
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:toggleLock",
                icon = "fas fa-archive",
                label = "Salle des preuves",
                job = {'police'}
            }
        }
    },
    
    -- ===================
    -- HÔPITAL PILLBOX
    -- ===================
    ['pillbox_main'] = {
        objName = 'v_ilev_cor_doorglassa',
        objCoords = vector3(324.9593, -580.4199, 43.2841),
        textCoords = vector3(324.9593, -581.4199, 44.2841),
        authorizedJobs = {'ambulance', 'doctor'},
        locked = true,
        distance = 2.0,
        size = 2.0,
        requiredItems = {
            {item = 'hospital_keycard', remove = false},
        },
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:toggleLock",
                icon = "fas fa-user-md",
                label = "Accès Hôpital",
                job = {'ambulance', 'doctor'}
            }
        }
    },
    
    ['pillbox_surgery'] = {
        objName = 'v_ilev_cor_doorglassb',
        objCoords = vector3(317.2924, -579.6281, 43.2841),
        textCoords = vector3(317.2924, -580.6281, 44.2841),
        authorizedJobs = {'ambulance', 'doctor'},
        authorizedGrades = {2, 3, 4}, -- Infirmier et plus
        locked = true,
        distance = 2.0,
        size = 2.0,
        requiredItems = {
            {item = 'surgery_keycard', remove = false},
        },
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:toggleLock",
                icon = "fas fa-surgical-scalpel",
                label = "Bloc opératoire",
                job = {'ambulance', 'doctor'}
            }
        }
    },
    
    -- ===================
    -- MÉCANO BENNYS
    -- ===================
    ['bennys_main'] = {
        objName = 'lr_prop_supermod_door_01',
        objCoords = vector3(-205.6828, -1310.6827, 30.2958),
        textCoords = vector3(-205.6828, -1311.6827, 31.2958),
        authorizedJobs = {'mechanic'},
        locked = false, -- Ouvert par défaut le jour
        distance = 2.5,
        size = 2.0,
        requiredItems = {
            {item = 'garage_keys', remove = false},
        },
        schedule = {
            openHour = 8,
            closeHour = 22
        },
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:toggleLock",
                icon = "fas fa-wrench",
                label = "Accès Garage",
                job = {'mechanic'}
            }
        }
    },
    
    -- ===================
    -- BANQUE FLEECA
    -- ===================
    ['fleeca_vault_1'] = {
        objName = 'hei_prop_heist_sec_door',
        objCoords = vector3(311.0, -284.0, 54.16),
        textCoords = vector3(311.0, -285.0, 55.16),
        authorizedJobs = {'police'},
        locked = true,
        distance = 2.0,
        size = 2.0,
        hasAlarm = true,
        requiresMultipleKeys = true,
        keyHolders = 2,
        requiredItems = {
            {item = 'bank_card', remove = true},
            {item = 'security_code', remove = true}
        },
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:multiKeyAccess",
                icon = "fas fa-vault",
                label = "Coffre-fort (2 clés requises)",
                job = {'police'}
            }
        },
        notifications = {
            success = "Coffre-fort accessible",
            fail = "Accès refusé - Sécurité activée",
            unauthorized = "Vous n'êtes pas autorisé",
            multiKeyWaiting = "En attente de la seconde clé...",
            multiKeySuccess = "Accès autorisé - Double authentification"
        }
    },
    
    -- ===================
    -- PORTE AVEC CODES
    -- ===================
    ['secure_warehouse'] = {
        objName = 'prop_facgate_04_l',
        objCoords = vector3(1087.7, -2006.9, 31.0),
        textCoords = vector3(1087.7, -2007.9, 32.0),
        authorizedJobs = {'police', 'fbi'},
        locked = true,
        distance = 3.0,
        size = 3.0,
        requiresCode = true,
        securityCode = "1234",
        hasAlarm = true,
        targetOptions = {
            {
                type = "client",
                event = "qb-doorlock:client:requestCode",
                icon = "fas fa-keyboard",
                label = "Saisir le code d'accès",
                job = {'police', 'fbi'}
            }
        }
    }
}

-- ================================
-- GROUPES DE PORTES
-- ================================

Config.DoorGroups = {
    ['lspd_all_cells'] = {
        doors = {'lspd_cells_main', 'lspd_cells_2', 'lspd_cells_3'},
        authorizedJobs = {'police'},
        requiredGrade = 3
    },
    
    ['hospital_emergency'] = {
        doors = {'pillbox_main', 'pillbox_surgery'},
        authorizedJobs = {'ambulance'},
        emergency = true
    }
}

-- Mapping des territoires pour les gangs (optionnel)
Config.TerritoryDoors = {
    ['south_los_santos'] = {'gang_hideout_1', 'gang_warehouse_1'},
    ['downtown'] = {'gang_hideout_2', 'gang_warehouse_2'},
    ['sandy_shores'] = {'gang_hideout_3', 'gang_warehouse_3'}
}

-- ================================
-- MESSAGES DE NOTIFICATION
-- ================================

Config.Locales = {
    ['door_locked'] = 'Porte verrouillée',
    ['door_unlocked'] = 'Porte déverrouillée',
    ['property_locked'] = 'Propriété verrouillée',          -- v2.0
    ['property_unlocked'] = 'Propriété déverrouillée',      -- v2.0
    ['no_authorization'] = 'Vous n\'avez pas l\'autorisation',
    ['missing_item'] = 'Il vous manque : %s',
    ['wrong_code'] = 'Code incorrect',
    ['enter_code'] = 'Entrez le code d\'accès',
    ['access_granted'] = 'Accès autorisé',
    ['access_denied'] = 'Accès refusé',
    ['tenant_access'] = 'Accès locataire',                  -- v2.0
    ['manager_access'] = 'Accès gestionnaire',              -- v2.0
    ['owner_access'] = 'Accès propriétaire',                -- v2.0
    ['key_expired'] = 'Clé expirée',                        -- v2.0
    ['multiple_doors'] = '%d portes dans cette propriété'   -- v2.0
}

-- ================================
-- CONFIGURATION AVANCÉE
-- ================================

-- Items spéciaux pour les systèmes avancés
Config.SpecialItems = {
    -- Duplication de clés
    ['key_duplication_kit'] = {
        successRate = 90,     -- 90% de réussite
        craftingTime = 10000, -- 10 secondes
        requiredJob = {'mechanic', 'realestate'}
    },
    
    -- Passe-partout
    ['master_key'] = {
        allowedJobs = {'realestate'},
        accessLevel = 'universal',
        restrictions = {'no_vault', 'no_evidence'}
    },
    
    -- Cartes d'accès temporaires
    ['temp_access_card'] = {
        duration = 3600,      -- 1 heure
        singleUse = true,
        canDuplicate = false
    }
}

-- Configuration des alarmes
Config.AlarmSystem = {
    enabled = true,
    cooldownTime = 300,      -- 5 minutes entre alarmes
    notifyJobs = {'police', 'security'},
    logToDiscord = true,
    soundRange = 50.0
}

-- Système de maintenance
Config.Maintenance = {
    enabled = true,
    allowedJobs = {'mechanic'},
    repairCost = 250,
    repairTime = 15000,      -- 15 secondes
    autoSchedule = true
}

-- ================================
-- COMPATIBILITÉ ET MIGRATION
-- ================================

-- Migration automatique v1.x vers v2.0
Config.Migration = {
    autoMigrate = true,
    backupBeforeMigration = true,
    migrateKeys = true,
    migrateLogs = true,
    
    -- Mapping des anciens vers nouveaux formats
    keyMigration = {
        ['house_key_'] = 'property_key_',
        ['apartment_key_'] = 'property_key_'
    },
    
    -- Mapping des types de portes
    doorTypeMigration = {
        ['house_'] = 'property_',
        ['apartment_'] = 'property_'
    }
}

-- Tests et monitoring
Config.Testing = {
    enableAutoTests = false,    -- Désactiver en production
    testInterval = 300000,      -- 5 minutes
    alertThreshold = 80,        -- Alerte si < 80% de réussite
    logResults = true
}

-- Version et informations
Config.Version = "1.2.0"
Config.Author = "QB-Doorlock Team"
Config.Description = "Système de verrouillage avancé avec intégration PS-Housing v1.x et v2.0.x"

print(string.format("[QB-DOORLOCK] Configuration chargée - Version %s", Config.Version))
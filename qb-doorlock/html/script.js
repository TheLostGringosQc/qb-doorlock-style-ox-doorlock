// ================================
// JAVASCRIPT NUI - QB-DOORLOCK
// html/script.js
// Interface interactive pour QB-Doorlock
// ================================

class QBDoorlock {
    constructor() {
        this.currentInterface = null;
        this.currentDoorId = null;
        this.currentCallback = null;
        this.soundEnabled = true;
        this.theme = 'default';
        this.animations = true;
        
        // Éléments DOM principaux
        this.container = document.querySelector('.container');
        this.codeInput = document.getElementById('codeInput');
        this.submitBtn = document.getElementById('submitBtn');
        this.cancelBtn = document.getElementById('cancelBtn');
        this.doorLabel = document.getElementById('doorLabel');
        this.errorMessage = document.getElementById('errorMessage');
        this.loadingElement = document.getElementById('loading');
        this.securityDots = document.querySelectorAll('.security-dot');
        
        // Configuration
        this.maxCodeLength = 4;
        this.keypadEnabled = true;
        this.autoSubmit = false;
        
        this.init();
    }
    
    // ================================
    // INITIALISATION
    // ================================
    
    init() {
        this.setupEventListeners();
        this.setupKeypad();
        this.setupKeyboardShortcuts();
        this.setupNotificationSystem();
        
        console.log('[QB-Doorlock] Interface NUI initialisée');
    }
    
    setupEventListeners() {
        // Boutons principaux
        this.submitBtn?.addEventListener('click', () => this.submitCode());
        this.cancelBtn?.addEventListener('click', () => this.closeInterface());
        
        // Input code
        this.codeInput?.addEventListener('input', (e) => this.handleCodeInput(e));
        this.codeInput?.addEventListener('keypress', (e) => this.handleKeyPress(e));
        
        // Événements de fenêtre
        window.addEventListener('message', (e) => this.handleMessage(e));
        window.addEventListener('keydown', (e) => this.handleGlobalKeyPress(e));
        
        // Empêcher la sélection et le clic droit
        document.addEventListener('contextmenu', (e) => e.preventDefault());
        document.addEventListener('selectstart', (e) => e.preventDefault());
        document.addEventListener('dragstart', (e) => e.preventDefault());
    }
    
    setupKeypad() {
        const keypadBtns = document.querySelectorAll('.keypad-btn');
        
        keypadBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const num = btn.getAttribute('data-num');
                const action = btn.getAttribute('data-action');
                
                this.playSound('click');
                
                if (num && this.codeInput.value.length < this.maxCodeLength) {
                    this.addDigit(num);
                } else if (action === 'clear') {
                    this.clearCode();
                } else if (action === 'backspace') {
                    this.removeLastDigit();
                }
            });
            
            // Effet visuel au survol
            btn.addEventListener('mouseenter', () => {
                if (this.animations) {
                    btn.style.transform = 'translateY(-2px)';
                }
            });
            
            btn.addEventListener('mouseleave', () => {
                if (this.animations) {
                    btn.style.transform = 'translateY(0)';
                }
            });
        });
    }
    
    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            if (!this.isVisible()) return;
            
            switch(e.key) {
                case 'Enter':
                    e.preventDefault();
                    this.submitCode();
                    break;
                case 'Escape':
                    e.preventDefault();
                    this.closeInterface();
                    break;
                case 'Backspace':
                    if (e.target !== this.codeInput) {
                        e.preventDefault();
                        this.removeLastDigit();
                    }
                    break;
                case 'Delete':
                    e.preventDefault();
                    this.clearCode();
                    break;
            }
        });
    }
    
    setupNotificationSystem() {
        // Créer le conteneur de notifications s'il n'existe pas
        if (!document.querySelector('.notification-container')) {
            const container = document.createElement('div');
            container.className = 'notification-container';
            document.body.appendChild(container);
        }
    }
    
    // ================================
    // GESTION DES MESSAGES
    // ================================
    
    handleMessage(event) {
        const data = event.data;
        
        switch (data.type) {
            case 'showCodeInput':
                this.showCodeInterface(data);
                break;
                
            case 'hideCodeInput':
            case 'hideUI':
                this.closeInterface();
                break;
                
            case 'codeResult':
                this.handleCodeResult(data);
                break;
                
            case 'updateUI':
                this.updateInterface(data);
                break;
                
            case 'playAnimation':
                this.playAnimation(data.animation);
                break;
                
            case 'showNotification':
                this.showNotification(data);
                break;
                
            case 'setTheme':
                this.setTheme(data.theme);
                break;
                
            case 'applySettings':
                this.applySettings(data.settings);
                break;
                
            default:
                console.log('[QB-Doorlock] Message non géré:', data);
        }
    }
    
    // ================================
    // INTERFACE PRINCIPALE
    // ================================
    
    showCodeInterface(data) {
        this.currentInterface = 'codeInput';
        this.currentDoorId = data.doorId;
        this.currentCallback = data.callback;
        
        // Mettre à jour le contenu
        if (this.doorLabel) {
            this.doorLabel.textContent = data.doorLabel || 'Porte sécurisée';
        }
        
        // Configurer l'input
        if (this.codeInput) {
            this.codeInput.value = '';
            this.codeInput.maxLength = data.maxLength || this.maxCodeLength;
            this.codeInput.placeholder = data.placeholder || '••••';
        }
        
        // Réinitialiser l'état
        this.clearErrors();
        this.updateSecurityDots();
        this.hideLoading();
        
        // Afficher l'interface
        this.showContainer();
        
        // Focus sur l'input après l'animation
        setTimeout(() => {
            this.codeInput?.focus();
        }, 400);
        
        this.playSound('open');
        console.log(`[QB-Doorlock] Interface ouverte pour: ${data.doorId}`);
    }
    
    closeInterface() {
        if (!this.isVisible()) return;
        
        this.hideContainer();
        this.playSound('close');
        
        // Callback de fermeture
        this.sendCallback(null);
        
        // Reset
        setTimeout(() => {
            this.currentInterface = null;
            this.currentDoorId = null;
            this.currentCallback = null;
            this.clearCode();
            this.clearErrors();
        }, 300);
        
        console.log('[QB-Doorlock] Interface fermée');
    }
    
    updateInterface(data) {
        if (data.type === 'codeResult') {
            if (data.success) {
                this.showSuccess(data.message || 'Code correct');
                this.playSound('success');
                setTimeout(() => this.closeInterface(), 1500);
            } else {
                this.showError(data.message || 'Code incorrect');
                this.playSound('error');
                this.clearCode();
            }
        }
    }
    
    // ================================
    // GESTION DU CODE
    // ================================
    
    handleCodeInput(event) {
        let value = event.target.value.replace(/[^0-9]/g, '');
        
        if (value.length > this.maxCodeLength) {
            value = value.slice(0, this.maxCodeLength);
        }
        
        event.target.value = value;
        this.updateSecurityDots();
        this.clearErrors();
        
        // Auto-submit si activé et code complet
        if (this.autoSubmit && value.length === this.maxCodeLength) {
            setTimeout(() => this.submitCode(), 500);
        }
    }
    
    handleKeyPress(event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            this.submitCode();
        }
    }
    
    addDigit(digit) {
        if (!this.codeInput || this.codeInput.value.length >= this.maxCodeLength) return;
        
        this.codeInput.value += digit;
        this.updateSecurityDots();
        this.clearErrors();
        
        // Effet visuel
        if (this.animations) {
            this.codeInput.style.transform = 'scale(1.02)';
            setTimeout(() => {
                this.codeInput.style.transform = 'scale(1)';
            }, 100);
        }
    }
    
    removeLastDigit() {
        if (!this.codeInput || this.codeInput.value.length === 0) return;
        
        this.codeInput.value = this.codeInput.value.slice(0, -1);
        this.updateSecurityDots();
        this.clearErrors();
    }
    
    clearCode() {
        if (!this.codeInput) return;
        
        this.codeInput.value = '';
        this.updateSecurityDots();
        this.clearErrors();
        
        // Effet visuel
        if (this.animations) {
            this.codeInput.style.transform = 'scale(0.98)';
            setTimeout(() => {
                this.codeInput.style.transform = 'scale(1)';
            }, 100);
        }
    }
    
    submitCode() {
        const code = this.codeInput?.value;
        
        if (!code || code.length < this.maxCodeLength) {
            this.showError(`Le code doit contenir ${this.maxCodeLength} chiffres`);
            this.playSound('error');
            return;
        }
        
        this.showLoading();
        this.playSound('submit');
        
        // Envoyer au serveur
        this.sendCallback({ code: code, doorId: this.currentDoorId });
        
        console.log(`[QB-Doorlock] Code soumis: ${code} pour ${this.currentDoorId}`);
    }
    
    // ================================
    // INTERFACE VISUELLE
    // ================================
    
    showContainer() {
        if (!this.container) return;
        
        this.container.classList.remove('closing');
        this.container.classList.add('show');
        
        if (this.animations) {
            this.container.style.animation = 'slideInUp 0.4s ease-out';
        }
    }
    
    hideContainer() {
        if (!this.container) return;
        
        this.container.classList.add('closing');
        
        if (this.animations) {
            this.container.style.animation = 'slideOutDown 0.3s ease-in';
        }
        
        setTimeout(() => {
            this.container.classList.remove('show', 'closing');
        }, 300);
    }
    
    updateSecurityDots() {
        const codeLength = this.codeInput?.value.length || 0;
        
        this.securityDots.forEach((dot, index) => {
            if (index < codeLength) {
                dot.classList.add('active');
            } else {
                dot.classList.remove('active');
            }
        });
    }
    
    showLoading() {
        if (this.loadingElement) {
            this.loadingElement.classList.add('show');
        }
        
        this.submitBtn && (this.submitBtn.disabled = true);
    }
    
    hideLoading() {
        if (this.loadingElement) {
            this.loadingElement.classList.remove('show');
        }
        
        this.submitBtn && (this.submitBtn.disabled = false);
    }
    
    showError(message) {
        if (this.errorMessage) {
            this.errorMessage.textContent = message;
            this.errorMessage.classList.add('show');
        }
        
        // Effet visuel d'erreur
        if (this.animations && this.container) {
            this.container.classList.add('access-denied');
            setTimeout(() => {
                this.container.classList.remove('access-denied');
            }, 600);
        }
    }
    
    showSuccess(message) {
        this.clearErrors();
        
        // Créer un message de succès temporaire
        const successMsg = document.createElement('div');
        successMsg.className = 'success-message show';
        successMsg.textContent = message;
        
        this.errorMessage?.parentNode.appendChild(successMsg);
        
        // Effet visuel de succès
        if (this.animations && this.container) {
            this.container.classList.add('success-feedback');
            setTimeout(() => {
                this.container.classList.remove('success-feedback');
            }, 600);
        }
        
        setTimeout(() => {
            successMsg.remove();
        }, 2000);
    }
    
    clearErrors() {
        if (this.errorMessage) {
            this.errorMessage.classList.remove('show');
        }
    }
    
    // ================================
    // SYSTÈME DE SONS
    // ================================
    
    playSound(type) {
        if (!this.soundEnabled) return;
        
        const sounds = {
            'click': 'CLICK_BACK',
            'submit': 'SELECT',
            'success': 'CHECKPOINT_PERFECT',
            'error': 'ERROR',
            'open': 'NAV_UP_DOWN',
            'close': 'BACK'
        };
        
        const soundName = sounds[type];
        if (soundName) {
            // Utiliser l'API FiveM si disponible
            if (window.invokeNative) {
                window.invokeNative('playSound', -1, soundName, 'HUD_FRONTEND_DEFAULT_SOUNDSET', 0, 0, 1);
            }
        }
    }
    
    // ================================
    // ANIMATIONS ET EFFETS
    // ================================
    
    playAnimation(animationType) {
        if (!this.animations || !this.container) return;
        
        const animations = {
            'slideIn': 'slideInUp 0.4s ease-out',
            'slideOut': 'slideOutDown 0.3s ease-in',
            'shake': 'shake 0.5s ease-in-out',
            'pulse': 'pulse 1s ease-in-out',
            'glow': 'glow 2s ease-in-out infinite'
        };
        
        const animation = animations[animationType];
        if (animation) {
            this.container.style.animation = animation;
        }
    }
    
    // ================================
    // SYSTÈME DE NOTIFICATIONS
    // ================================
    
    showNotification(data) {
        const container = document.querySelector('.notification-container');
        if (!container) return;
        
        const notification = document.createElement('div');
        notification.className = `notification ${data.notifyType || 'info'}`;
        
        const icon = this.getNotificationIcon(data.notifyType);
        
        notification.innerHTML = `
            <div class="notification-icon">${icon}</div>
            <div class="notification-content">
                <div class="notification-title">${data.title || 'QB-Doorlock'}</div>
                <div class="notification-message">${data.message}</div>
            </div>
            <button class="notification-close">&times;</button>
        `;
        
        container.appendChild(notification);
        
        // Fermer automatiquement
        const duration = data.duration || 3000;
        setTimeout(() => {
            this.removeNotification(notification);
        }, duration);
        
        // Bouton de fermeture
        notification.querySelector('.notification-close').addEventListener('click', () => {
            this.removeNotification(notification);
        });
    }
    
    removeNotification(notification) {
        if (notification) {
            notification.style.animation = 'slideLeft 0.3s ease-in reverse';
            setTimeout(() => {
                notification.remove();
            }, 300);
        }
    }
    
    getNotificationIcon(type) {
        const icons = {
            'success': '✅',
            'error': '❌',
            'warning': '⚠️',
            'info': 'ℹ️',
            'door': '🚪',
            'lock': '🔒',
            'unlock': '🔓',
            'alarm': '🚨',
            'key': '🔑'
        };
        
        return icons[type] || 'ℹ️';
    }
    
    // ================================
    // SYSTÈME DE THÈMES
    // ================================
    
    setTheme(themeName) {
        this.theme = themeName;
        document.body.className = document.body.className.replace(/theme-\w+/g, '');
        
        if (themeName !== 'default') {
            document.body.classList.add(`theme-${themeName}`);
        }
        
        console.log(`[QB-Doorlock] Thème appliqué: ${themeName}`);
    }
    
    applySettings(settings) {
        if (settings.soundEnabled !== undefined) {
            this.soundEnabled = settings.soundEnabled;
        }
        
        if (settings.animations !== undefined) {
            this.animations = settings.animations;
        }
        
        if (settings.theme) {
            this.setTheme(settings.theme);
        }
        
        if (settings.maxCodeLength) {
            this.maxCodeLength = settings.maxCodeLength;
        }
        
        if (settings.autoSubmit !== undefined) {
            this.autoSubmit = settings.autoSubmit;
        }
        
        console.log('[QB-Doorlock] Paramètres appliqués:', settings);
    }
    
    // ================================
    // UTILITAIRES
    // ================================
    
    isVisible() {
        return this.container && this.container.classList.contains('show');
    }
    
    sendCallback(data) {
        if (typeof fetch !== 'undefined') {
            const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'qb-doorlock';
            
            fetch(`https://${resourceName}/submitCode`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data || {})
            }).catch(error => {
                console.error('[QB-Doorlock] Erreur callback:', error);
            });
        }
    }
    
    handleGlobalKeyPress(event) {
        // Gérer les raccourcis globaux
        if (event.ctrlKey && event.key === 'r') {
            event.preventDefault();
            this.reloadInterface();
        }
    }
    
    reloadInterface() {
        console.log('[QB-Doorlock] Rechargement de l\'interface...');
        this.closeInterface();
        setTimeout(() => {
            window.location.reload();
        }, 100);
    }
    
    // ================================
    // API PUBLIQUE
    // ================================
    
    // Méthodes exposées pour utilisation externe
    getAPI() {
        return {
            show: (data) => this.showCodeInterface(data),
            hide: () => this.closeInterface(),
            update: (data) => this.updateInterface(data),
            setTheme: (theme) => this.setTheme(theme),
            playSound: (type) => this.playSound(type),
            showNotification: (data) => this.showNotification(data),
            isVisible: () => this.isVisible(),
            getSettings: () => ({
                soundEnabled: this.soundEnabled,
                animations: this.animations,
                theme: this.theme,
                maxCodeLength: this.maxCodeLength,
                autoSubmit: this.autoSubmit
            })
        };
    }
}

// ================================
// GESTIONNAIRE D'EFFETS VISUELS
// ================================

class VisualEffects {
    static createParticles(container, count = 20) {
        if (!container) return;
        
        const particles = document.createElement('div');
        particles.className = 'particles';
        
        for (let i = 0; i < count; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            particle.style.left = Math.random() * 100 + '%';
            particle.style.animationDelay = Math.random() * 6 + 's';
            particle.style.animationDuration = (4 + Math.random() * 4) + 's';
            particles.appendChild(particle);
        }
        
        container.appendChild(particles);
        
        // Supprimer après 10 secondes
        setTimeout(() => {
            particles.remove();
        }, 10000);
    }
    
    static createRipple(element, event) {
        const ripple = document.createElement('span');
        const rect = element.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = event.clientX - rect.left - size / 2;
        const y = event.clientY - rect.top - size / 2;
        
        ripple.style.width = ripple.style.height = size + 'px';
        ripple.style.left = x + 'px';
        ripple.style.top = y + 'px';
        ripple.className = 'ripple';
        
        element.appendChild(ripple);
        
        setTimeout(() => {
            ripple.remove();
        }, 600);
    }
    
    static typeWriter(element, text, speed = 50) {
        if (!element) return;
        
        element.textContent = '';
        let i = 0;
        
        const timer = setInterval(() => {
            if (i < text.length) {
                element.textContent += text.charAt(i);
                i++;
            } else {
                clearInterval(timer);
            }
        }, speed);
    }
}

// ================================
// GESTIONNAIRE DE STOCKAGE LOCAL
// ================================

class LocalStorage {
    static save(key, data) {
        try {
            localStorage.setItem(`qb-doorlock-${key}`, JSON.stringify(data));
        } catch (error) {
            console.warn('[QB-Doorlock] Impossible de sauvegarder:', error);
        }
    }
    
    static load(key, defaultValue = null) {
        try {
            const data = localStorage.getItem(`qb-doorlock-${key}`);
            return data ? JSON.parse(data) : defaultValue;
        } catch (error) {
            console.warn('[QB-Doorlock] Impossible de charger:', error);
            return defaultValue;
        }
    }
    
    static remove(key) {
        try {
            localStorage.removeItem(`qb-doorlock-${key}`);
        } catch (error) {
            console.warn('[QB-Doorlock] Impossible de supprimer:', error);
        }
    }
    
    static clear() {
        try {
            const keys = Object.keys(localStorage).filter(key => key.startsWith('qb-doorlock-'));
            keys.forEach(key => localStorage.removeItem(key));
        } catch (error) {
            console.warn('[QB-Doorlock] Impossible de vider:', error);
        }
    }
}

// ================================
// GESTIONNAIRE DE PERFORMANCE
// ================================

class PerformanceManager {
    constructor() {
        this.fps = 0;
        this.lastTime = performance.now();
        this.frameCount = 0;
        this.monitoring = false;
    }
    
    startMonitoring() {
        this.monitoring = true;
        this.monitor();
    }
    
    stopMonitoring() {
        this.monitoring = false;
    }
    
    monitor() {
        if (!this.monitoring) return;
        
        const currentTime = performance.now();
        this.frameCount++;
        
        if (currentTime - this.lastTime >= 1000) {
            this.fps = Math.round((this.frameCount * 1000) / (currentTime - this.lastTime));
            this.frameCount = 0;
            this.lastTime = currentTime;
            
            // Ajuster la qualité si FPS bas
            if (this.fps < 30) {
                this.reducePerfomance();
            } else if (this.fps > 50) {
                this.increasePerfomance();
            }
        }
        
        requestAnimationFrame(() => this.monitor());
    }
    
    reducePerfomance() {
        // Désactiver certains effets visuels
        document.body.classList.add('low-performance');
    }
    
    increasePerfomance() {
        // Réactiver les effets visuels
        document.body.classList.remove('low-performance');
    }
    
    getFPS() {
        return this.fps;
    }
}

// ================================
// DEBUGGING ET DÉVELOPPEMENT
// ================================

class DebugMode {
    static enabled = false;
    
    static enable() {
        this.enabled = true;
        this.createDebugPanel();
        console.log('[QB-Doorlock] Mode debug activé');
    }
    
    static disable() {
        this.enabled = false;
        const panel = document.getElementById('debug-panel');
        if (panel) panel.remove();
        console.log('[QB-Doorlock] Mode debug désactivé');
    }
    
    static log(...args) {
        if (this.enabled) {
            console.log('[QB-Doorlock Debug]', ...args);
        }
    }
    
    static createDebugPanel() {
        const panel = document.createElement('div');
        panel.id = 'debug-panel';
        panel.style.cssText = `
            position: fixed;
            top: 10px;
            left: 10px;
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            font-size: 12px;
            z-index: 9999;
            min-width: 200px;
        `;
        
        panel.innerHTML = `
            <h4>QB-Doorlock Debug</h4>
            <div id="debug-info"></div>
            <button onclick="qbDoorlock.reloadInterface()">Reload</button>
            <button onclick="DebugMode.disable()">Close</button>
        `;
        
        document.body.appendChild(panel);
        
        // Mettre à jour les infos de debug
        setInterval(() => {
            const info = document.getElementById('debug-info');
            if (info) {
                info.innerHTML = `
                    <div>Interface: ${qbDoorlock.currentInterface || 'None'}</div>
                    <div>Door ID: ${qbDoorlock.currentDoorId || 'None'}</div>
                    <div>Theme: ${qbDoorlock.theme}</div>
                    <div>Sounds: ${qbDoorlock.soundEnabled ? 'On' : 'Off'}</div>
                    <div>Animations: ${qbDoorlock.animations ? 'On' : 'Off'}</div>
                    <div>FPS: ${performanceManager.getFPS()}</div>
                `;
            }
        }, 1000);
    }
}

// ================================
// INITIALISATION GLOBALE
// ================================

// Variables globales
let qbDoorlock;
let performanceManager;

// Initialisation au chargement de la page
document.addEventListener('DOMContentLoaded', () => {
    try {
        // Créer l'instance principale
        qbDoorlock = new QBDoorlock();
        performanceManager = new PerformanceManager();
        
        // Charger les paramètres sauvegardés
        const savedSettings = LocalStorage.load('settings', {});
        if (Object.keys(savedSettings).length > 0) {
            qbDoorlock.applySettings(savedSettings);
        }
        
        // Démarrer le monitoring des performances
        performanceManager.startMonitoring();
        
        // Exposer l'API globalement
        window.QBDoorlock = qbDoorlock.getAPI();
        window.VisualEffects = VisualEffects;
        window.DebugMode = DebugMode;
        
        console.log('[QB-Doorlock] Interface complètement initialisée');
        
        // Mode debug si paramètre URL
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('debug') === 'true') {
            DebugMode.enable();
        }
        
    } catch (error) {
        console.error('[QB-Doorlock] Erreur d\'initialisation:', error);
    }
});

// Sauvegarde des paramètres avant fermeture
window.addEventListener('beforeunload', () => {
    if (qbDoorlock) {
        LocalStorage.save('settings', qbDoorlock.getAPI().getSettings());
    }
});

// Gestion des erreurs globales
window.addEventListener('error', (event) => {
    console.error('[QB-Doorlock] Erreur JS:', event.error);
    
    // Notifier l'erreur si possible
    if (qbDoorlock && qbDoorlock.showNotification) {
        qbDoorlock.showNotification({
            notifyType: 'error',
            title: 'Erreur Interface',
            message: 'Une erreur est survenue dans l\'interface',
            duration: 5000
        });
    }
});

// Détection de perte de connexion
window.addEventListener('online', () => {
    console.log('[QB-Doorlock] Connexion rétablie');
});

window.addEventListener('offline', () => {
    console.warn('[QB-Doorlock] Connexion perdue');
    if (qbDoorlock) {
        qbDoorlock.showNotification({
            notifyType: 'warning',
            title: 'Connexion',
            message: 'Connexion au serveur perdue',
            duration: 3000
        });
    }
});

// ================================
// STYLES CSS POUR JS EFFECTS
// ================================

const dynamicStyles = `
    .ripple {
        position: absolute;
        border-radius: 50%;
        background: rgba(0, 212, 255, 0.3);
        transform: scale(0);
        animation: rippleAnimation 0.6s linear;
        pointer-events: none;
    }
    
    @keyframes rippleAnimation {
        to {
            transform: scale(4);
            opacity: 0;
        }
    }
    
    .low-performance * {
        animation-duration: 0.1s !important;
        transition-duration: 0.1s !important;
    }
    
    .low-performance .particle {
        display: none;
    }
    
    .typewriter {
        overflow: hidden;
        border-right: 2px solid var(--primary-color);
        white-space: nowrap;
        animation: blink 1s infinite;
    }
    
    @keyframes blink {
        0%, 50% { border-color: var(--primary-color); }
        51%, 100% { border-color: transparent; }
    }
`;

// Injecter les styles dynamiques
const styleSheet = document.createElement('style');
styleSheet.textContent = dynamicStyles;
document.head.appendChild(styleSheet);

// Message de fin d'initialisation
console.log('%c[QB-Doorlock] 🚪🔐 Interface NUI chargée avec succès!', 'color: #00d4ff; font-weight: bold; font-size: 14px;');
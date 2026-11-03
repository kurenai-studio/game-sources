import EventBus from '../utils/EventBus.js';
import { AREA_INFO, ELEMENTS, NPC_NAMES } from '../constants.js';
import { QUESTS, questProgress, questTarget } from '../data/quests.js';
import { ACHIEVEMENT_CATEGORIES } from '../data/achievements.js';
import { Sound } from '../utils/SoundSystem.js';
import { Music } from '../utils/MusicSystem.js';
import { xpToNext, masteryPercent, xpToNextElement } from '../systems/XPSystem.js';
import { SaveSystem } from '../systems/SaveSystem.js';
import { spendStatPoint } from '../systems/XPSystem.js';
import { richToHtml } from '../utils/RichText.js';

const MAX_MESSAGES = 80;

export class UIScene extends Phaser.Scene {
    constructor() { super({ key: 'UI', active: false }); }

    create() {
        this._bindDOM();
        this._bindEvents();
        this._bindButtons();
        this._updateAll();
    }

    _bindDOM() {
        this._els = {
            charName:   document.getElementById('char-name'),
            level:      document.getElementById('char-level'),
            hpBar:      document.getElementById('hp-bar'),
            hpText:     document.getElementById('hp-text'),
            focusBar:   document.getElementById('focus-bar'),
            focusText:  document.getElementById('focus-text'),
            xpBar:      document.getElementById('xp-bar'),
            xpText:     document.getElementById('xp-text'),
            statStr:    document.getElementById('stat-str'),
            statInt:    document.getElementById('stat-int'),
            statAgi:    document.getElementById('stat-agi'),
            statVit:    document.getElementById('stat-vit'),
            statGold:   document.getElementById('stat-gold'),
            areaName:   document.getElementById('area-name'),
            areaTopic:  document.getElementById('area-topic'),
            questTracker: document.getElementById('quest-tracker'),
            headerArea: document.getElementById('header-area'),
            masterList: document.getElementById('mastery-list'),
            elementalList: document.getElementById('elemental-mastery-list'),
            chatMsgs:   document.getElementById('chat-messages'),
            chatLog:    document.getElementById('chat-log'),
            minimap:    document.getElementById('minimap-canvas'),
            btnInv:     document.getElementById('btn-inventory'),
            btnChar:    document.getElementById('btn-character'),
            btnQuest:   document.getElementById('btn-quests'),
            btnBook:    document.getElementById('btn-books'),
            btnSkill:   document.getElementById('btn-skill'),
            btnComp:    document.getElementById('btn-compendium'),
            btnSave:    document.getElementById('btn-save'),
        };
    }

    _bindEvents() {
        EventBus.on('player-hp-change',     ({ player }) => this._updateVitals(player));
        EventBus.on('player-xp-change',     ({ player }) => this._updateXP(player));
        EventBus.on('element-xp-change',    ({ player }) => this._updateElementalMastery(player));
        EventBus.on('player-level-up',      ({ player }) => {
            this._updateAll(player);
            this.addMsg(`SUBIU DE NÍVEL! Agora você é nível ${player.level}!`, 'levelup');
            if (player.availableStatPoints > 0) this._showStatPointPopup(player);
        });
        EventBus.on('player-stats-changed', ({ player }) => this._updateStats(player));
        EventBus.on('area-changed',         ({ areaId }) => this._updateArea(areaId));
        EventBus.on('chat',                 ({ msg, type }) => this.addMsg(msg, type));
        EventBus.on('minimap-update',       ({ mapMgr, player }) => this._updateMinimap(mapMgr, player));

        // Rastreador de missão no HUD — objetivo atual sempre visível
        const updTracker = () => this._updateQuestTracker();
        EventBus.on('quest-accepted', updTracker);
        EventBus.on('quest-complete', updTracker);
        EventBus.on('quest-claimed',  updTracker);
        EventBus.on('combat-end',     updTracker);
        EventBus.on('area-changed',   updTracker);

        // Action button alerts
        EventBus.on('item-alert',  () => this._setAlert('btnInv', true));
        EventBus.on('skill-alert', () => this._setAlert('btnSkill', true));
        EventBus.on('quest-complete', () => this._setAlert('btnQuest', true));
        EventBus.on('achievement-unlocked', ({ achievement }) => this._showAchievementBanner(achievement));
        EventBus.on('autosave', () => this._showAutosaveIndicator());

        this._updateQuestTracker();
    }

    _updateQuestTracker() {
        const el = this._els.questTracker;
        if (!el) return;
        const p = this.registry.get('player');
        const entries = Object.entries(p?.questLog || {})
            .filter(([, s]) => s === 'active' || s === 'complete');
        el.classList.remove('quest-done');
        if (!entries.length) {
            el.textContent = 'Nenhuma missão ativa';
            return;
        }
        // Prioriza missão completa (para lembrar de entregar); senão a 1ª ativa
        const [id, status] = entries.find(([, s]) => s === 'complete') || entries[0];
        const quest = QUESTS[id];
        if (!quest) { el.textContent = 'Nenhuma missão ativa'; return; }

        if (status === 'complete') {
            el.classList.add('quest-done');
            el.innerHTML = `<b>${quest.name}</b><br>✓ Completa — fale com ${NPC_NAMES[quest.giver] || quest.giver}`;
        } else {
            const cur = questProgress(p, quest);
            const tgt = questTarget(quest);
            const pct = quest.objective?.type === 'mastery' ? '%' : '';
            el.innerHTML = `<b>${quest.name}</b><br>${cur}${pct} / ${tgt}${pct}`;
        }
    }

    _bindButtons() {
        this._els.btnInv?.addEventListener('click', () => {
            const ws = this.scene.get('World');
            if (ws) { ws.pauseForOverlay(); ws.scene.launch('Inventory'); }
            this._setAlert('btnInv', false);
            const player = this.registry.get('player');
            if (player) player.pendingItemAlert = false;
        });
        this._els.btnChar?.addEventListener('click', () => {
            const ws = this.scene.get('World');
            if (ws) { ws.pauseForOverlay(); ws.scene.launch('Character'); }
        });
        this._els.btnQuest?.addEventListener('click', () => {
            const ws = this.scene.get('World');
            if (ws) { ws.pauseForOverlay(); ws.scene.launch('Quest'); }
            this._setAlert('btnQuest', false);
        });
        this._els.btnBook?.addEventListener('click', () => {
            const ws = this.scene.get('World');
            if (ws) { ws.pauseForOverlay(); ws.scene.launch('Book'); }
        });
        this._els.btnSkill?.addEventListener('click', () => {
            const ws = this.scene.get('World');
            if (ws) { ws.pauseForOverlay(); ws.scene.launch('Skill'); }
            this._setAlert('btnSkill', false);
        });
        this._els.btnComp?.addEventListener('click', () => {
            const ws = this.scene.get('World');
            if (ws) { ws.pauseForOverlay(); ws.scene.launch('Compendium'); }
        });
        this._els.btnSave?.addEventListener('click', () => {
            const player = this.registry.get('player');
            if (player) {
                SaveSystem.autoSave(player);
                Sound.save();
                this.addMsg('Jogo salvo!', 'system');
            }
        });

        const btnSound = document.getElementById('btn-sound');
        if (btnSound) {
            btnSound.textContent = Sound.enabled ? '🔊' : '🔇';
            if (!Sound.enabled) btnSound.classList.add('muted');
            btnSound.addEventListener('click', () => {
                const on = Sound.toggle();
                Music.setEnabled(on);
                btnSound.textContent = on ? '🔊' : '🔇';
                btnSound.classList.toggle('muted', !on);
                if (on) Sound.click();
            });
        }

        // Volume slider — controls SFX + music, persisted via Sound.setVolume
        const volSlider = document.getElementById('vol-slider');
        if (volSlider) {
            const saved = parseFloat(localStorage.getItem('meanfall_vol') || '0.35');
            volSlider.value = Math.round(saved * 100);
            Music.setVolume(saved);
            volSlider.addEventListener('input', () => {
                const v = volSlider.value / 100;
                Sound.setVolume(v);
                Music.setVolume(v);
            });
            // Audible reference blip when the user releases the slider
            volSlider.addEventListener('change', () => Sound.click());
        }
    }

    _showAutosaveIndicator() {
        let el = document.getElementById('autosave-indicator');
        if (!el) {
            el = document.createElement('div');
            el.id = 'autosave-indicator';
            Object.assign(el.style, {
                position: 'fixed', bottom: '12px', right: '12px',
                padding: '4px 10px',
                background: 'rgba(0,20,10,0.88)',
                border: '1px solid #33aa55',
                color: '#55dd88',
                fontFamily: 'Courier New, monospace',
                fontSize: '11px',
                borderRadius: '3px',
                opacity: '0',
                transition: 'opacity 0.3s ease',
                pointerEvents: 'none',
                zIndex: '9999',
            });
            el.textContent = '✓ Salvo';
            document.body.appendChild(el);
        }
        el.style.opacity = '1';
        clearTimeout(this._autosaveTimer);
        this._autosaveTimer = setTimeout(() => { el.style.opacity = '0'; }, 1500);
    }

    _setAlert(btnKey, on) {
        const btn = this._els[btnKey];
        if (!btn) return;
        if (on) btn.classList.add('alert');
        else    btn.classList.remove('alert');
    }

    _showAchievementBanner(ach) {
        // Queue banners so they don't stack
        if (!this._achQueue) this._achQueue = [];
        this._achQueue.push(ach);
        if (this._achQueue.length === 1) this._drainAchQueue();
    }

    _drainAchQueue() {
        if (!this._achQueue?.length) return;
        const ach = this._achQueue[0];
        const { xpEarned = 0, goldEarned = 0 } = ach;

        const cat    = ACHIEVEMENT_CATEGORIES[ach.category];
        const catColor = cat?.color || '#d4af37';

        // Choose border color based on rarity if available
        let borderColor = catColor;
        if (ach.rarity === 'rare') borderColor = '#c0c0c0'; // Silver-ish
        if (ach.rarity === 'legendary') borderColor = '#ffd700'; // Gold

        const banner = document.createElement('div');
        banner.id = 'achievement-banner';
        banner.style.borderColor = borderColor;
        banner.style.boxShadow   = `0 4px 24px rgba(0,0,0,0.85), 0 0 18px ${borderColor}55`;
        
        let rewardHtml = '';
        if (xpEarned > 0) rewardHtml += `<span class="ach-reward xp">+${xpEarned} XP</span>`;
        if (goldEarned > 0) rewardHtml += `<span class="ach-reward gold">+${goldEarned} Ouro</span>`;

        banner.innerHTML = `
            <span class="ach-icon" style="color:${borderColor}">${ach.icon}</span>
            <span class="ach-body">
                <span class="ach-title" style="color:${borderColor}">${cat?.label?.toUpperCase() || 'CONQUISTA'}</span>
                <span class="ach-name">${ach.name}</span>
                <span class="ach-desc">${ach.description}</span>
                ${rewardHtml ? `<div class="ach-rewards-row">${rewardHtml}</div>` : ''}
            </span>`;
        document.body.appendChild(banner);

        // Animate in
        requestAnimationFrame(() => banner.classList.add('ach-visible'));

        // Auto-dismiss after 3.5s
        setTimeout(() => {
            banner.classList.remove('ach-visible');
            banner.addEventListener('transitionend', () => {
                banner.remove();
                this._achQueue.shift();
                if (this._achQueue.length) {
                    setTimeout(() => this._drainAchQueue(), 300);
                }
            }, { once: true });
        }, 3500);

        this.addMsg(`★ CONQUISTA: ${ach.name} — ${ach.description}`, 'levelup');
    }

    addMsg(text, type = '') {
        const el = this._els.chatMsgs || document.getElementById('chat-messages');
        if (!el) return;
        const div = document.createElement('div');
        div.className = `chat-msg ${type}`;

        // Timestamp in São Paulo (Brasília) timezone — HH:MM:SS
        const tsStr = new Intl.DateTimeFormat('pt-BR', {
            timeZone: 'America/Sao_Paulo',
            hour: '2-digit', minute: '2-digit', second: '2-digit',
            hour12: false,
        }).format(new Date());
        const tsSpan = `<span class="chat-time">[${tsStr}]</span> `;

        // Apply both layers: explicit {{tag:value}} tokens and keyword auto-highlight
        const inner = highlightKeywords(richToHtml(String(text)));
        div.innerHTML = tsSpan + inner;
        el.appendChild(div);

        while (el.children.length > MAX_MESSAGES) el.removeChild(el.firstChild);

        // Auto-scroll
        const log = this._els.chatLog || document.getElementById('chat-log');
        if (log) log.scrollTop = log.scrollHeight;
        el.scrollTop = el.scrollHeight;
    }

    _updateAll(player) {
        player = player || this.registry.get('player');
        if (!player) return;
        this._updateVitals(player);
        this._updateXP(player);
        this._updateStats(player);
        this._updateMastery(player);
        this._updateElementalMastery(player);
        const e = this._els;
        if (e.charName) e.charName.textContent = player.name || 'Aventureiro';
        if (e.level) e.level.textContent = player.level;
        // Restore alert states from player flags
        this._setAlert('btnInv', !!player.pendingItemAlert);
    }

    _updateVitals(player) {
        player = player || this.registry.get('player');
        if (!player) return;
        const e = this._els;
        setBar(e.hpBar, e.hpText, player.hp, player.maxHp);
        setBar(e.focusBar, e.focusText, player.focus, player.maxFocus);
        if (e.level) e.level.textContent = player.level;
    }

    _updateXP(player) {
        player = player || this.registry.get('player');
        if (!player) return;
        const next = xpToNext(player.level);
        const pct  = Math.min(100, (player.xp / next) * 100);
        setBar(this._els.xpBar, this._els.xpText, player.xp, next);
        if (this._els.xpBar) this._els.xpBar.style.width = pct + '%';
    }

    _updateStats(player) {
        player = player || this.registry.get('player');
        if (!player) return;
        const e = this._els;
        if (e.statStr)  e.statStr.textContent  = player.strength;
        if (e.statInt)  e.statInt.textContent  = player.intelligence;
        if (e.statAgi)  e.statAgi.textContent  = player.agility;
        if (e.statVit)  e.statVit.textContent  = player.vitality;
        if (e.statGold) e.statGold.textContent = player.gold;
        this._updateMastery(player);
    }

    _updateMastery(player) {
        player = player || this.registry.get('player');
        if (!player || !this._els.masterList) return;
        const el = this._els.masterList;
        el.innerHTML = '';
        for (const [area, m] of Object.entries(player.mastery)) {
            const info = AREA_INFO[area];
            if (!info) continue;
            const pct = masteryPercent(m);
            const div = document.createElement('div');
            div.className = 'mastery-item';
            div.innerHTML = `
                <div class="mastery-name">${info.displayName}</div>
                <div class="mastery-bar-track"><div class="mastery-bar-fill" style="width:${pct}%"></div></div>
                <span class="mastery-pct">${pct}% (${m.correct}/${m.attempted})</span>`;
            el.appendChild(div);
        }
    }

    _getElementIconUrl(id) {
        if (!this._elementIconUrls) this._elementIconUrls = {};
        if (!this._elementIconUrls[id]) {
            const canvas = this.textures.get(`icon_element_${id}`)?.getSourceImage?.();
            this._elementIconUrls[id] = canvas ? canvas.toDataURL() : '';
        }
        return this._elementIconUrls[id];
    }

    _updateElementalMastery(player) {
        player = player || this.registry.get('player');
        if (!player || !this._els.elementalList) return;
        const el = this._els.elementalList;
        el.innerHTML = '';

        for (const [id, data] of Object.entries(ELEMENTS)) {
            const m = player.elementalMastery[id];
            if (!m) continue;

            const next = xpToNextElement(m.level);
            const pct = Math.min(100, (m.xp / next) * 100);
            const iconUrl = this._getElementIconUrl(id);

            const div = document.createElement('div');
            div.className = 'element-mastery-item';
            div.innerHTML = `
                <div class="element-header">
                    <img src="${iconUrl}" class="element-icon" />
                    <span class="element-name" style="color: #${data.color.toString(16).padStart(6, '0')}">${data.name}</span>
                    <span class="element-level">Nv. ${m.level}</span>
                </div>
                <div class="element-bar-track">
                    <div class="element-bar-fill" style="width:${pct}%; background-color: #${data.color.toString(16).padStart(6, '0')}"></div>
                </div>
            `;
            el.appendChild(div);
        }
    }

    _updateArea(areaId) {
        const info = AREA_INFO[areaId];
        if (!info) return;
        const e = this._els;
        if (e.areaName)   e.areaName.textContent   = info.displayName;
        if (e.areaTopic)  e.areaTopic.textContent   = info.topic;
        if (e.headerArea) e.headerArea.textContent  = info.displayName;
    }

    _updateMinimap(mapMgr, player) {
        if (!mapMgr || !this._els.minimap) return;
        mapMgr.drawMinimap(this._els.minimap, player);
        mapMgr.drawMinimapPlayer(this._els.minimap, player.position.x, player.position.y);
    }

    _showStatPointPopup(player) {
        let popup = document.getElementById('stat-point-popup');
        if (!popup) {
            popup = document.createElement('div');
            popup.id = 'stat-point-popup';
            popup.className = 'visible';
            document.body.appendChild(popup);
        }

        popup.innerHTML = `<h3>SUBIU DE NÍVEL! Distribua 1 ponto de atributo</h3>`;
        const stats = [
            ['strength', 'Força (dano)'],
            ['intelligence', 'Inteligência (XP bônus)'],
            ['agility', 'Agilidade (esquiva)'],
            ['vitality', 'Vitalidade (HP)'],
        ];
        stats.forEach(([key, label]) => {
            const btn = document.createElement('button');
            btn.className = 'stat-point-btn';
            btn.textContent = `${label} (atual: ${player[key]})`;
            btn.onclick = () => {
                spendStatPoint(player, key);
                this.registry.set('player', player);
                EventBus.emit('player-stats-changed', { player });
                popup.classList.remove('visible');
            };
            popup.appendChild(btn);
        });
        popup.classList.add('visible');
    }
}

function setBar(barEl, textEl, cur, max) {
    if (!barEl || !textEl) return;
    const pct = max > 0 ? Math.max(0, Math.min(100, (cur / max) * 100)) : 0;
    barEl.style.width = pct + '%';
    textEl.textContent = `${Math.floor(cur)}/${Math.floor(max)}`;
}

function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, c => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
    }[c]));
}

// Skip text that already contains <span> markers so we don't double-process
function highlightKeywords(text) {
    // Only escape the parts NOT already wrapped in spans
    if (text.includes('<span')) {
        // assume input was already markup; only auto-augment plain segments
        return text.replace(/>([^<]+)</g, (m, body) => {
            return '>' + augmentPlain(body) + '<';
        });
    }
    return augmentPlain(escapeHtml(text));
}

function augmentPlain(s) {
    // XP / HP / Foco / Ouro counters
    s = s.replace(/(\+\d+\s*XP)/gi,                '<span class="kw-xp">$1</span>');
    s = s.replace(/([+−-]\d+\s*HP)/gi,             '<span class="kw-damage">$1</span>');
    s = s.replace(/(\+\d+\s*Foco)/gi,              '<span class="kw-focus">$1</span>');
    s = s.replace(/(\d+\s*ouro)/gi,                '<span class="kw-gold">$1</span>');
    // Level
    s = s.replace(/\b(NÍVEL\s*\d+|nv\.?\s*\d+|NIVEL\s*ACIMA|nível\s*\d+)\b/gi, '<span class="kw-level">$1</span>');
    // Combat keywords
    s = s.replace(/\b(CRÍTICO!?|SUPER\s*EFICAZ!?)\b/gi, '<span class="kw-crit">$1</span>');
    s = s.replace(/\b(ESQUIVA|esquivou|desviou)\b/gi,  '<span class="kw-dodge">$1</span>');
    s = s.replace(/\b(LOOT:?|ITENS?\s*OBTIDOS?)\b/gi,   '<span class="kw-loot">$1</span>');
    s = s.replace(/\b(VITÓRIA!?|venceu)\b/gi,           '<span class="kw-good">$1</span>');
    s = s.replace(/\b(DERROTAD[OA]|FALHOU)\b/gi,        '<span class="kw-bad">$1</span>');
    // Rarity & importance
    s = s.replace(/\b(Lendári[oa]|LENDÁRIO)\b/gi,       '<span class="kw-legendary">$1</span>');
    s = s.replace(/\b(Épic[oa]|ÉPICO)\b/gi,             '<span class="kw-epic">$1</span>');
    s = s.replace(/\b(Rar[oa]|RARO|raro)\b/gi,          '<span class="kw-rare">$1</span>');
    s = s.replace(/\b(Incomum|INCOMUM)\b/gi,            '<span class="kw-uncommon">$1</span>');
    s = s.replace(/\b(Proibid[oa]|Essencial|Muito Importante|Importante)\b/gi, '<span class="kw-rarity">$1</span>');
    // Quest / dialog
    s = s.replace(/\b(missão|Missão|Missões)\b/g,       '<span class="kw-quest">$1</span>');
    // Elements
    s = s.replace(/\b(Fogo|FIRE)\b/g,                   '<span class="kw-fire">$1</span>');
    s = s.replace(/\b(Água|WATER)\b/g,                  '<span class="kw-water">$1</span>');
    s = s.replace(/\b(Terra|EARTH)\b/g,                 '<span class="kw-earth">$1</span>');
    s = s.replace(/\b(Gelo|ICE)\b/g,                    '<span class="kw-ice">$1</span>');
    s = s.replace(/\b(Trevas|SHADOW)\b/g,               '<span class="kw-shadow">$1</span>');
    // Damage / heal as words
    s = s.replace(/\b(DANO|dano)\b/g,                   '<span class="kw-damage">$1</span>');
    s = s.replace(/\b(cura|HEAL|curou|regenerou)\b/gi,  '<span class="kw-heal">$1</span>');
    return s;
}

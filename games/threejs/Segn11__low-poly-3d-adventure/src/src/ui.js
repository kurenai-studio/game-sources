import { sounds } from './audio.js';

const LOCALES = {
  en: {
    pauseTitle: "GAME PAUSED",
    pauseSubtitle: "Take a breather, hopper!",
    resume: "RESUME PLAY",
    restart: "RESTART RUN",
    questTitle: "MISSION LOG",
    questSubtitle: "Collect all 5 Grand Power Stars to conquer Starfall Isle!",
    settingsTitle: "SETTINGS",
    settingsSubtitle: "Audio, display & accessibility options",
    masterVol: "Master Volume",
    sfxVol: "SFX Volume",
    musicVol: "Music Volume",
    screenShake: "Screen Shake",
    language: "Language",
    victoryTitle: "⭐ YOU WIN! ⭐",
    victorySubtitle: "You reached the Summit and mastered Starfall Isle!",
    playAgain: "PLAY AGAIN",
    controlsTitle: "🎮 CONTROLS",
    controlsHint: "WASD Move | SPACE Jump | SHIFT Sprint | F / SHIFT+SPACE Dive | C Ground Pound | TAB Mission Log",
    missions: [
      { name: "Meadow Grove Discovery", desc: "Discover the secret grove tucked behind Meadow Camp" },
      { name: "Crimson Constellation", desc: "Collect all 8 hidden Red Coins scattered across the world" },
      { name: "High-Flying Hop", desc: "Bounce to the sky apex above the giant mushroom" },
      { name: "Gears of Antiquity", desc: "Traverse the rotating clockwork ruins to the high stone arch" },
      { name: "Celestial Apex Star", desc: "Claim the legendary Star upon the Celestial Summit Altar" }
    ]
  },
  es: {
    pauseTitle: "JUEGO PAUSADO",
    pauseSubtitle: "¡Toma un respiro, saltador!",
    resume: "CONTINUAR",
    restart: "REINICIAR",
    questTitle: "REGISTRO DE MISIONES",
    questSubtitle: "¡Consigue las 5 Superestrellas para conquistar Starfall Isle!",
    settingsTitle: "AJUSTES",
    settingsSubtitle: "Opciones de audio, pantalla y accesibilidad",
    masterVol: "Volumen General",
    sfxVol: "Volumen Efectos",
    musicVol: "Volumen Música",
    screenShake: "Temblor de Pantalla",
    language: "Idioma",
    victoryTitle: "⭐ ¡HAS GANADO! ⭐",
    victorySubtitle: "¡Alcanzaste la Cima y dominaste Starfall Isle!",
    playAgain: "JUGAR DE NUEVO",
    controlsTitle: "🎮 CONTROLES",
    controlsHint: "WASD Mover | ESPACIO Saltar | SHIFT Correr | F Zambullida | C Salto Bomba | TAB Misiones",
    missions: [
      { name: "Descubrimiento de la Arboleda", desc: "Descubre la arboleda secreta detrás del campamento" },
      { name: "Constelación Carmesí", desc: "Recoge las 8 Monedas Rojas ocultas por el mundo" },
      { name: "Salto de Gran Altura", desc: "Rebota hasta la cima del cielo sobre la seta gigante" },
      { name: "Engranajes de la Antigüedad", desc: "Cruza las ruinas mecánicas hasta el arco de piedra" },
      { name: "Estrella del Ápice Celestial", desc: "Reclama la Estrella legendaria en el Altar Celestial" }
    ]
  },
  fr: {
    pauseTitle: "JEU EN PAUSE",
    pauseSubtitle: "Prenez un instant pour respirer !",
    resume: "REPRENDRE",
    restart: "RECOMMENCER",
    questTitle: "JOURNAL DES MISSIONS",
    questSubtitle: "Récupérez les 5 Grandes Étoiles pour conquérir l'Île !",
    settingsTitle: "PARAMÈTRES",
    settingsSubtitle: "Options audio, affichage et accessibilité",
    masterVol: "Volume Principal",
    sfxVol: "Volume Effets",
    musicVol: "Volume Musique",
    screenShake: "Secousse de Caméra",
    language: "Langue",
    victoryTitle: "⭐ VICTOIRE ! ⭐",
    victorySubtitle: "Vous avez atteint le Sommet Céleste !",
    playAgain: "REJOUER",
    controlsTitle: "🎮 COMMANDES",
    controlsHint: "WASD Déplacement | ESPACE Saut | SHIFT Sprint | F Plongeon | C Écrasement | TAB Missions",
    missions: [
      { name: "Le Bosquet Secret", desc: "Découvrez le bosquet caché derrière le camp" },
      { name: "Constellation Pourpre", desc: "Rassemblez les 8 Pièces Rouges du monde" },
      { name: "Bond dans les Nuages", desc: "Rebondissez au sommet du ciel sur le champignon" },
      { name: "Rouages Antiques", desc: "Traversez les ruines mécaniques jusqu'à l'arche" },
      { name: "Étoile du Sommet Céleste", desc: "Brandissez l'Étoile sacrée sur l'autel céleste" }
    ]
  },
  ja: {
    pauseTitle: "ゲーム一時停止",
    pauseSubtitle: "少し休憩しましょう！",
    resume: "再開する",
    restart: "最初からやり直す",
    questTitle: "ミッションリスト",
    questSubtitle: "5つのグランドパワースターを集めて島を制覇しよう！",
    settingsTitle: "設定",
    settingsSubtitle: "サウンド・グラフィック・操作設定",
    masterVol: "マスター音量",
    sfxVol: "効果音音量",
    musicVol: "BGM音量",
    screenShake: "画面揺れ効果",
    language: "言語",
    victoryTitle: "⭐ ステージクリア！ ⭐",
    victorySubtitle: "星降る島の頂点に到達しました！おめでとう！",
    playAgain: "もう一度遊ぶ",
    controlsTitle: "🎮 操作方法",
    controlsHint: "WASD 移動 | SPACE ジャンプ | SHIFT ダッシュ | F ダイブ | C ヒップドロップ | TAB ミッション",
    missions: [
      { name: "木立の秘密のスター", desc: "スタート地点の裏にある秘密の木立を発見する" },
      { name: "深紅の星座", desc: "世界に隠された8枚の赤コインを全て集める" },
      { name: "ハイフライング・ホップ", desc: "巨大キノコで空高く飛び跳ねる" },
      { name: "古代の歯車遺跡", desc: "回転する歯車を渡り、古代の石のアーチへ到達する" },
      { name: "天空の頂天スター", desc: "天空神殿の祭壇に輝く伝説のスターを手に入れる" }
    ]
  },
  de: {
    pauseTitle: "SPIEL PAUSIERT",
    pauseSubtitle: "Kurz durchatmen, Springer!",
    resume: "WEITERSPIELEN",
    restart: "NEUSTART",
    questTitle: "MISSIONS-LOG",
    questSubtitle: "Sammle alle 5 Großen Sterne um die Insel zu meistern!",
    settingsTitle: "EINSTELLUNGEN",
    settingsSubtitle: "Audio-, Anzeige- und Steuerungsoptionen",
    masterVol: "Gesamtlautstärke",
    sfxVol: "Effektlautstärke",
    musicVol: "Musiklautstärke",
    screenShake: "Kamerarütteln",
    language: "Sprache",
    victoryTitle: "⭐ DU HAST GEWONNEN! ⭐",
    victorySubtitle: "Du hast den Himmlischen Gipfel erreicht!",
    playAgain: "NOCHMAL SPIELEN",
    controlsTitle: "🎮 STEUERUNG",
    controlsHint: "WASD Bewegen | LEERTASTE Sprung | SHIFT Sprint | F Hechtsprung | C Stampfattacke | TAB Missionen",
    missions: [
      { name: "Geheimnisvoller Hain", desc: "Finde den versteckten Hain hinter dem Lager" },
      { name: "Rote Sternenkonstellation", desc: "Sammle alle 8 versteckten roten Münzen" },
      { name: "Himmelhoher Sprung", desc: "Katapultiere dich mit dem Riesenpilz in den Himmel" },
      { name: "Uralte Zahnräder", desc: "Überwinde die mechanischen Ruinen zum Steinbogen" },
      { name: "Himmlischer Gipfelstern", desc: "Erringe den Stern auf dem Gipfelaltar" }
    ]
  }
};

export class UIManager {
  constructor(game) {
    this.game = game;
    this.app = document.getElementById('app');

    this.timerSeconds = 0;
    this.timerInterval = null;
    this.isPaused = false;
    this.currentLanguage = 'en';
    this.screenShakeEnabled = true;

    this.starsCollectedState = [false, false, false, false, false];

    this.inputState = {
      forward: false,
      backward: false,
      left: false,
      right: false,
      jump: false,
      jumpPressed: false,
      dive: false,
      divePressed: false,
      pound: false,
      poundPressed: false,
      sprint: false
    };

    // Gamepad state cache
    this.gamepadConnected = false;
    this.prevGamepadButtons = {};

    this.buildHTML();
    this.cacheElements();
    this.bindKeyboard();
    this.bindTouchControls();
    this.bindEvents();
    this.startTimer();
    this.setLanguage('en');
  }

  buildHTML() {
    this.app.insertAdjacentHTML('beforeend', `
      <!-- HUD OVERLAY -->
      <div id="hud-overlay">
        <div class="hud-top">
          <div class="hud-stats-group">
            <!-- Health Hearts -->
            <div class="glass-panel heart-container" id="hearts-container">
              <svg class="heart-icon" viewBox="0 0 24 24" fill="#ff4757">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
              </svg>
              <svg class="heart-icon" viewBox="0 0 24 24" fill="#ff4757">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
              </svg>
              <svg class="heart-icon" viewBox="0 0 24 24" fill="#ff4757">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
              </svg>
            </div>

            <!-- Coin Counter -->
            <div class="glass-panel stat-badge coins" id="coins-badge">
              <span class="icon">🪙</span>
              <span id="coins-count">0</span>
            </div>

            <!-- Red Coins Counter -->
            <div class="glass-panel stat-badge red-coins" id="red-coins-badge">
              <span class="icon">🔴</span>
              <span id="red-coins-count">0 / 8</span>
            </div>

            <!-- Stars Counter -->
            <div class="glass-panel stat-badge stars" id="stars-badge" title="Click to view Mission Log (TAB)">
              <span class="icon">⭐</span>
              <span id="stars-count">0 / 5</span>
            </div>
          </div>

          <div class="hud-actions-group">
            <div class="glass-panel gamepad-badge" id="gamepad-badge">🎮 PAD</div>
            <div class="glass-panel timer-badge" id="timer-display">00:00</div>
            <button class="hud-btn" id="btn-quest" title="Mission Log (TAB)">📜</button>
            <button class="hud-btn" id="btn-sound" title="Toggle Sound">🔊</button>
            <button class="hud-btn" id="btn-music" title="Toggle Music">🎵</button>
            <button class="hud-btn" id="btn-settings" title="Settings">⚙️</button>
            <button class="hud-btn" id="btn-pause" title="Pause Game (ESC)">⏸</button>
          </div>
        </div>

        <div id="notification-banner" class="glass-panel">
          Checkpoint Reached!
        </div>

        <div class="hud-bottom">
          <div class="glass-panel controls-hint" id="controls-hint">
            <div class="hint-title">
              <span id="txt-controls-title">🎮 CONTROLS</span>
              <span style="font-size: 0.8rem; opacity: 0.7;">Click + Drag to Orbit Camera</span>
            </div>
            <div id="txt-controls-hint">
              <span class="kbd-key">W</span><span class="kbd-key">A</span><span class="kbd-key">S</span><span class="kbd-key">D</span> Move |
              <span class="kbd-key">SPACE</span> Jump |
              <span class="kbd-key">SHIFT</span> Sprint |
              <span class="kbd-key">F</span> Dive |
              <span class="kbd-key">C</span> Ground Pound |
              <span class="kbd-key">TAB</span> Missions
            </div>
          </div>
        </div>
      </div>

      <!-- ON-SCREEN MOBILE TOUCH CONTROLS -->
      <div id="touch-controls">
        <div class="touch-stick-zone" id="touch-stick">
          <div class="touch-stick-knob" id="touch-knob"></div>
        </div>
        <div class="touch-action-buttons">
          <button class="touch-btn pound-btn" id="touch-pound" title="Ground Pound">⬇</button>
          <button class="touch-btn dive-btn" id="touch-dive" title="Belly Dive">🐬</button>
          <button class="touch-btn jump-btn" id="touch-jump" title="Jump">▲</button>
        </div>
      </div>

      <!-- PAUSE MODAL -->
      <div class="modal-overlay" id="pause-modal">
        <div class="glass-panel modal-card">
          <h2 class="modal-title" id="txt-pause-title">GAME PAUSED</h2>
          <p class="modal-subtitle" id="txt-pause-subtitle">Take a breather, hopper!</p>
          <div class="modal-actions">
            <button class="btn-primary" id="btn-resume">RESUME PLAY</button>
            <button class="btn-secondary" id="btn-restart">RESTART RUN</button>
          </div>
        </div>
      </div>

      <!-- MISSION QUEST LOG MODAL -->
      <div class="modal-overlay" id="quest-modal">
        <div class="glass-panel modal-card">
          <h2 class="modal-title" id="txt-quest-title">MISSION LOG</h2>
          <p class="modal-subtitle" id="txt-quest-subtitle">Collect all 5 Grand Power Stars to conquer Starfall Isle!</p>
          
          <div class="mission-list" id="mission-items-list">
            <!-- Populated dynamically via JS -->
          </div>

          <button class="btn-primary" id="btn-close-quest">CLOSE LOG</button>
        </div>
      </div>

      <!-- SETTINGS MODAL -->
      <div class="modal-overlay" id="settings-modal">
        <div class="glass-panel modal-card">
          <h2 class="modal-title" id="txt-settings-title">SETTINGS</h2>
          <p class="modal-subtitle" id="txt-settings-subtitle">Audio, display & accessibility options</p>

          <div class="settings-section">
            <div class="setting-row">
              <span class="setting-label" id="txt-master-vol">Master Volume</span>
              <input type="range" class="setting-slider" id="slider-master" min="0" max="1" step="0.05" value="0.8">
            </div>

            <div class="setting-row">
              <span class="setting-label" id="txt-sfx-vol">SFX Volume</span>
              <input type="range" class="setting-slider" id="slider-sfx" min="0" max="1" step="0.05" value="0.9">
            </div>

            <div class="setting-row">
              <span class="setting-label" id="txt-music-vol">Music Volume</span>
              <input type="range" class="setting-slider" id="slider-music" min="0" max="1" step="0.05" value="0.55">
            </div>

            <div class="setting-row">
              <span class="setting-label" id="txt-shake">Screen Shake</span>
              <input type="checkbox" id="toggle-shake" checked style="width: 22px; height: 22px; accent-color: #ff4757; cursor: pointer;">
            </div>

            <div class="setting-row">
              <span class="setting-label" id="txt-lang">Language</span>
              <div class="lang-selector">
                <button class="lang-btn active" data-lang="en">EN</button>
                <button class="lang-btn" data-lang="es">ES</button>
                <button class="lang-btn" data-lang="fr">FR</button>
                <button class="lang-btn" data-lang="ja">日本語</button>
                <button class="lang-btn" data-lang="de">DE</button>
              </div>
            </div>
          </div>

          <button class="btn-primary" id="btn-close-settings">DONE</button>
        </div>
      </div>

      <!-- VICTORY CELEBRATION MODAL -->
      <div class="modal-overlay" id="victory-modal">
        <div class="glass-panel modal-card">
          <h2 class="modal-title" id="txt-victory-title">⭐ YOU WIN! ⭐</h2>
          <p class="modal-subtitle" id="txt-victory-subtitle">You reached the Summit and mastered Starfall Isle!</p>

          <div class="modal-stats-grid">
            <div class="stat-box">
              <div class="stat-box-label">TIME</div>
              <div class="stat-box-value" id="victory-time">00:00</div>
            </div>
            <div class="stat-box">
              <div class="stat-box-label">COINS</div>
              <div class="stat-box-value" id="victory-coins">0</div>
            </div>
            <div class="stat-box">
              <div class="stat-box-label">STARS</div>
              <div class="stat-box-value" style="color: #ffd700;">5 / 5</div>
            </div>
          </div>

          <button class="btn-primary" id="btn-play-again">PLAY AGAIN</button>
        </div>
      </div>
    `);
  }

  cacheElements() {
    this.canvas = document.getElementById('game-canvas');
    this.heartsContainer = document.getElementById('hearts-container');
    this.heartIcons = Array.from(this.heartsContainer.querySelectorAll('.heart-icon'));
    this.coinsCount = document.getElementById('coins-count');
    this.coinsBadge = document.getElementById('coins-badge');
    this.redCoinsCount = document.getElementById('red-coins-count');
    this.redCoinsBadge = document.getElementById('red-coins-badge');
    this.starsCount = document.getElementById('stars-count');
    this.starsBadge = document.getElementById('stars-badge');
    this.timerDisplay = document.getElementById('timer-display');
    this.gamepadBadge = document.getElementById('gamepad-badge');
    this.notificationBanner = document.getElementById('notification-banner');

    this.pauseModal = document.getElementById('pause-modal');
    this.questModal = document.getElementById('quest-modal');
    this.settingsModal = document.getElementById('settings-modal');
    this.victoryModal = document.getElementById('victory-modal');

    this.btnResume = document.getElementById('btn-resume');
    this.btnRestart = document.getElementById('btn-restart');
    this.btnCloseQuest = document.getElementById('btn-close-quest');
    this.btnCloseSettings = document.getElementById('btn-close-settings');
    this.btnPlayAgain = document.getElementById('btn-play-again');

    this.btnQuest = document.getElementById('btn-quest');
    this.btnSound = document.getElementById('btn-sound');
    this.btnMusic = document.getElementById('btn-music');
    this.btnSettings = document.getElementById('btn-settings');
    this.btnPause = document.getElementById('btn-pause');

    this.sliderMaster = document.getElementById('slider-master');
    this.sliderSfx = document.getElementById('slider-sfx');
    this.sliderMusic = document.getElementById('slider-music');
    this.toggleShake = document.getElementById('toggle-shake');
    this.missionItemsList = document.getElementById('mission-items-list');
  }

  setLanguage(lang) {
    if (!LOCALES[lang]) return;
    this.currentLanguage = lang;
    const t = LOCALES[lang];

    document.getElementById('txt-pause-title').textContent = t.pauseTitle;
    document.getElementById('txt-pause-subtitle').textContent = t.pauseSubtitle;
    this.btnResume.textContent = t.resume;
    this.btnRestart.textContent = t.restart;

    document.getElementById('txt-quest-title').textContent = t.questTitle;
    document.getElementById('txt-quest-subtitle').textContent = t.questSubtitle;

    document.getElementById('txt-settings-title').textContent = t.settingsTitle;
    document.getElementById('txt-settings-subtitle').textContent = t.settingsSubtitle;
    document.getElementById('txt-master-vol').textContent = t.masterVol;
    document.getElementById('txt-sfx-vol').textContent = t.sfxVol;
    document.getElementById('txt-music-vol').textContent = t.musicVol;
    document.getElementById('txt-shake').textContent = t.screenShake;
    document.getElementById('txt-lang').textContent = t.language;

    document.getElementById('txt-victory-title').textContent = t.victoryTitle;
    document.getElementById('txt-victory-subtitle').textContent = t.victorySubtitle;
    this.btnPlayAgain.textContent = t.playAgain;

    document.getElementById('txt-controls-title').textContent = t.controlsTitle;
    document.getElementById('txt-controls-hint').innerHTML = `
      <span class="kbd-key">W</span><span class="kbd-key">A</span><span class="kbd-key">S</span><span class="kbd-key">D</span> Move |
      <span class="kbd-key">SPACE</span> Jump |
      <span class="kbd-key">SHIFT</span> Sprint |
      <span class="kbd-key">F</span> Dive |
      <span class="kbd-key">C</span> Ground Pound |
      <span class="kbd-key">TAB</span> Missions
    `;

    // Highlight active language button
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.lang === lang);
    });

    this.renderMissionsList();
  }

  renderMissionsList() {
    const t = LOCALES[this.currentLanguage] || LOCALES.en;
    this.missionItemsList.innerHTML = t.missions.map((m, idx) => {
      const isDone = this.starsCollectedState[idx];
      return `
        <div class="mission-item ${isDone ? 'completed' : ''}">
          <div class="mission-info">
            <h4>⭐ ${idx + 1}. ${m.name}</h4>
            <p>${m.desc}</p>
          </div>
          <div class="mission-badge">${isDone ? '✅' : '🔒'}</div>
        </div>
      `;
    }).join('');
  }

  bindKeyboard() {
    window.addEventListener('keydown', (e) => {
      sounds.ensureContext();
      if (!sounds.bgmTimer && sounds.musicEnabled && !sounds.muted) {
        sounds.startBGM();
      }

      switch (e.code) {
        case 'KeyW':
        case 'ArrowUp':
          this.inputState.forward = true;
          break;
        case 'KeyS':
        case 'ArrowDown':
          this.inputState.backward = true;
          break;
        case 'KeyA':
        case 'ArrowLeft':
          this.inputState.left = true;
          break;
        case 'KeyD':
        case 'ArrowRight':
          this.inputState.right = true;
          break;
        case 'Space':
          if (this.inputState.sprint && !this.inputState.dive) {
            this.inputState.divePressed = true;
            this.inputState.dive = true;
          } else {
            if (!this.inputState.jump) {
              this.inputState.jumpPressed = true;
            }
            this.inputState.jump = true;
          }
          e.preventDefault();
          break;
        case 'KeyF':
        case 'KeyE':
          if (!this.inputState.dive) {
            this.inputState.divePressed = true;
          }
          this.inputState.dive = true;
          break;
        case 'KeyC':
        case 'ControlLeft':
        case 'ControlRight':
          if (!this.inputState.pound) {
            this.inputState.poundPressed = true;
          }
          this.inputState.pound = true;
          break;
        case 'ShiftLeft':
        case 'ShiftRight':
          this.inputState.sprint = true;
          break;
        case 'KeyQ':
          this.game.cameraController.rotateBy(-0.4);
          break;
        case 'Tab':
        case 'KeyM':
          e.preventDefault();
          this.toggleQuestModal();
          break;
        case 'Escape':
          this.togglePause();
          break;
      }
    });

    window.addEventListener('keyup', (e) => {
      switch (e.code) {
        case 'KeyW':
        case 'ArrowUp':
          this.inputState.forward = false;
          break;
        case 'KeyS':
        case 'ArrowDown':
          this.inputState.backward = false;
          break;
        case 'KeyA':
        case 'ArrowLeft':
          this.inputState.left = false;
          break;
        case 'KeyD':
        case 'ArrowRight':
          this.inputState.right = false;
          break;
        case 'Space':
          this.inputState.jump = false;
          this.inputState.dive = false;
          break;
        case 'KeyF':
        case 'KeyE':
          this.inputState.dive = false;
          break;
        case 'KeyC':
        case 'ControlLeft':
        case 'ControlRight':
          this.inputState.pound = false;
          break;
        case 'ShiftLeft':
        case 'ShiftRight':
          this.inputState.sprint = false;
          break;
      }
    });
  }

  bindTouchControls() {
    const stickZone = document.getElementById('touch-stick');
    const knob = document.getElementById('touch-knob');
    const jumpBtn = document.getElementById('touch-jump');
    const diveBtn = document.getElementById('touch-dive');
    const poundBtn = document.getElementById('touch-pound');

    let activeTouchId = null;
    const center = { x: 65, y: 65 };
    const maxRadius = 45;

    stickZone.addEventListener('touchstart', (e) => {
      sounds.ensureContext();
      if (!sounds.bgmTimer && sounds.musicEnabled) sounds.startBGM();
      const touch = e.changedTouches[0];
      activeTouchId = touch.identifier;
    }, { passive: true });

    stickZone.addEventListener('touchmove', (e) => {
      for (let i = 0; i < e.changedTouches.length; i++) {
        const touch = e.changedTouches[i];
        if (touch.identifier === activeTouchId) {
          const rect = stickZone.getBoundingClientRect();
          const tx = touch.clientX - rect.left - center.x;
          const ty = touch.clientY - rect.top - center.y;
          const dist = Math.hypot(tx, ty);

          const clampedDist = Math.min(dist, maxRadius);
          const angle = Math.atan2(ty, tx);

          const kx = Math.cos(angle) * clampedDist;
          const ky = Math.sin(angle) * clampedDist;
          knob.style.transform = `translate(calc(-50% + ${kx}px), calc(-50% + ${ky}px))`;

          const normX = kx / maxRadius;
          const normY = ky / maxRadius;

          this.inputState.forward = normY < -0.25;
          this.inputState.backward = normY > 0.25;
          this.inputState.left = normX < -0.25;
          this.inputState.right = normX > 0.25;
          this.inputState.sprint = (clampedDist > maxRadius * 0.85);
        }
      }
    }, { passive: true });

    const resetStick = (e) => {
      for (let i = 0; i < e.changedTouches.length; i++) {
        if (e.changedTouches[i].identifier === activeTouchId) {
          activeTouchId = null;
          knob.style.transform = `translate(-50%, -50%)`;
          this.inputState.forward = false;
          this.inputState.backward = false;
          this.inputState.left = false;
          this.inputState.right = false;
          this.inputState.sprint = false;
        }
      }
    };

    stickZone.addEventListener('touchend', resetStick, { passive: true });
    stickZone.addEventListener('touchcancel', resetStick, { passive: true });

    // Buttons
    jumpBtn.addEventListener('touchstart', (e) => {
      sounds.ensureContext();
      this.inputState.jumpPressed = true;
      this.inputState.jump = true;
      e.preventDefault();
    });
    jumpBtn.addEventListener('touchend', () => { this.inputState.jump = false; });

    diveBtn.addEventListener('touchstart', (e) => {
      sounds.ensureContext();
      this.inputState.divePressed = true;
      this.inputState.dive = true;
      e.preventDefault();
    });
    diveBtn.addEventListener('touchend', () => { this.inputState.dive = false; });

    poundBtn.addEventListener('touchstart', (e) => {
      sounds.ensureContext();
      this.inputState.poundPressed = true;
      this.inputState.pound = true;
      e.preventDefault();
    });
    poundBtn.addEventListener('touchend', () => { this.inputState.pound = false; });
  }

  pollGamepad(delta) {
    if (!navigator.getGamepads) return;
    const gamepads = navigator.getGamepads();
    const pad = gamepads[0] || gamepads[1];

    if (!pad) {
      if (this.gamepadConnected) {
        this.gamepadConnected = false;
        this.gamepadBadge.classList.remove('connected');
      }
      return;
    }

    if (!this.gamepadConnected) {
      this.gamepadConnected = true;
      this.gamepadBadge.classList.add('connected');
      this.showNotification("🎮 Controller Connected: " + pad.id.slice(0, 20));
      this.vibrateGamepad(150, 0.4, 0.6);
    }

    // Left Stick Movement
    const deadzone = 0.22;
    const lx = Math.abs(pad.axes[0]) > deadzone ? pad.axes[0] : 0;
    const ly = Math.abs(pad.axes[1]) > deadzone ? pad.axes[1] : 0;

    if (Math.hypot(lx, ly) > 0.01) {
      this.inputState.left = lx < -0.3;
      this.inputState.right = lx > 0.3;
      this.inputState.forward = ly < -0.3;
      this.inputState.backward = ly > 0.3;
      this.inputState.sprint = Math.hypot(lx, ly) > 0.85;
    }

    // Right Stick Camera Orbit
    const rx = Math.abs(pad.axes[2]) > deadzone ? pad.axes[2] : 0;
    const ry = Math.abs(pad.axes[3]) > deadzone ? pad.axes[3] : 0;

    if (Math.abs(rx) > 0.05) {
      this.game.cameraController.targetYaw -= rx * delta * 3.5;
    }
    if (Math.abs(ry) > 0.05) {
      this.game.cameraController.targetPitch += ry * delta * 2.2;
      this.game.cameraController.targetPitch = Math.max(0.08, Math.min(Math.PI / 2.3, this.game.cameraController.targetPitch));
    }

    // Buttons
    // Button 0 (A / Cross): Jump
    const btnA = pad.buttons[0] && pad.buttons[0].pressed;
    if (btnA && !this.prevGamepadButtons[0]) {
      this.inputState.jumpPressed = true;
      sounds.ensureContext();
      if (!sounds.bgmTimer && sounds.musicEnabled) sounds.startBGM();
    }
    this.inputState.jump = btnA;

    // Button 2 (X / Square): Dive
    const btnX = pad.buttons[2] && pad.buttons[2].pressed;
    if (btnX && !this.prevGamepadButtons[2]) {
      this.inputState.divePressed = true;
    }
    this.inputState.dive = btnX;

    // Button 1 (B / Circle) or Trigger: Ground Pound
    const btnB = (pad.buttons[1] && pad.buttons[1].pressed) || (pad.buttons[7] && pad.buttons[7].pressed);
    if (btnB && !this.prevGamepadButtons[1]) {
      this.inputState.poundPressed = true;
    }
    this.inputState.pound = btnB;

    // Button 3 (Y / Triangle): Mission Log
    const btnY = pad.buttons[3] && pad.buttons[3].pressed;
    if (btnY && !this.prevGamepadButtons[3]) {
      this.toggleQuestModal();
    }

    // Button 9 (Start / Options): Pause
    const btnStart = pad.buttons[9] && pad.buttons[9].pressed;
    if (btnStart && !this.prevGamepadButtons[9]) {
      this.togglePause();
    }

    // Cache button states
    for (let i = 0; i < 16; i++) {
      this.prevGamepadButtons[i] = pad.buttons[i] ? pad.buttons[i].pressed : false;
    }
  }

  vibrateGamepad(duration = 200, weakMagnitude = 0.4, strongMagnitude = 0.7) {
    if (!navigator.getGamepads) return;
    const gamepads = navigator.getGamepads();
    const pad = gamepads[0] || gamepads[1];
    if (pad && pad.vibrationActuator && typeof pad.vibrationActuator.playEffect === 'function') {
      pad.vibrationActuator.playEffect('dual-rumble', {
        startDelay: 0,
        duration,
        weakMagnitude,
        strongMagnitude
      }).catch(() => {});
    }
  }

  bindEvents() {
    this.btnSound.addEventListener('click', () => {
      const isMuted = sounds.toggleMute();
      this.btnSound.textContent = isMuted ? '🔇' : '🔊';
    });

    this.btnMusic.addEventListener('click', () => {
      const isEnabled = sounds.toggleMusic();
      this.btnMusic.textContent = isEnabled ? '🎵' : '✖';
    });

    this.btnPause.addEventListener('click', () => this.togglePause());
    this.btnResume.addEventListener('click', () => this.togglePause());

    this.btnQuest.addEventListener('click', () => this.toggleQuestModal());
    this.starsBadge.addEventListener('click', () => this.toggleQuestModal());
    this.btnCloseQuest.addEventListener('click', () => this.toggleQuestModal());

    this.btnSettings.addEventListener('click', () => this.toggleSettingsModal());
    this.btnCloseSettings.addEventListener('click', () => this.toggleSettingsModal());

    this.btnRestart.addEventListener('click', () => {
      this.pauseModal.classList.remove('active');
      this.isPaused = false;
      this.game.restart();
    });

    this.btnPlayAgain.addEventListener('click', () => {
      this.victoryModal.classList.remove('active');
      this.game.restart();
    });

    // Sliders
    this.sliderMaster.addEventListener('input', (e) => {
      sounds.setMasterVolume(parseFloat(e.target.value));
    });
    this.sliderSfx.addEventListener('input', (e) => {
      sounds.setSFXVolume(parseFloat(e.target.value));
    });
    this.sliderMusic.addEventListener('input', (e) => {
      sounds.setMusicVolume(parseFloat(e.target.value));
    });
    this.toggleShake.addEventListener('change', (e) => {
      this.screenShakeEnabled = e.target.checked;
    });

    // Language buttons
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        this.setLanguage(btn.dataset.lang);
      });
    });

    // Custom game events
    window.addEventListener('coinCollected', (e) => {
      this.coinsCount.textContent = e.detail.current;
      this.coinsBadge.classList.remove('bounce-text');
      void this.coinsBadge.offsetWidth;
      this.coinsBadge.classList.add('bounce-text');
    });

    window.addEventListener('redCoinCollected', (e) => {
      this.redCoinsCount.textContent = `${e.detail.current} / ${e.detail.total}`;
      this.redCoinsBadge.classList.remove('bounce-text');
      void this.redCoinsBadge.offsetWidth;
      this.redCoinsBadge.classList.add('bounce-text');
      this.showNotification(`🔴 Red Coin ${e.detail.current} of ${e.detail.total}!`);
      this.vibrateGamepad(120, 0.3, 0.5);
    });

    window.addEventListener('starCollected', (e) => {
      this.starsCount.textContent = `${e.detail.current} / ${e.detail.total}`;
      this.showNotification(`⭐ Star Collected: ${e.detail.name}!`);
      this.starsBadge.classList.remove('bounce-text');
      void this.starsBadge.offsetWidth;
      this.starsBadge.classList.add('bounce-text');

      // Mark mission complete
      if (e.detail.current <= 5) {
        this.starsCollectedState[e.detail.current - 1] = true;
        this.renderMissionsList();
      }

      this.vibrateGamepad(350, 0.7, 0.95);
    });

    window.addEventListener('checkpointReached', (e) => {
      this.showNotification(`🚩 Checkpoint: ${e.detail.name}`);
      sounds.playCheckpoint();
      this.vibrateGamepad(180, 0.4, 0.6);
    });

    window.addEventListener('notification', (e) => {
      if (e.detail && e.detail.text) {
        this.showNotification(e.detail.text);
      }
    });

    window.addEventListener('scorePopup', (e) => {
      this.spawnScorePopup(e.detail);
    });

    window.addEventListener('gameWon', () => {
      this.showVictory();
      this.vibrateGamepad(600, 0.8, 1.0);
    });
  }

  spawnScorePopup(detail) {
    const el = document.createElement('div');
    el.className = 'score-popup';
    el.textContent = detail.text || '+100';

    // Approximate screen position or center of screen
    el.style.left = '50%';
    el.style.top = '40%';
    this.app.appendChild(el);

    setTimeout(() => {
      if (el.parentNode) el.parentNode.removeChild(el);
    }, 1300);
  }

  showNotification(text) {
    this.notificationBanner.textContent = text;
    this.notificationBanner.classList.add('active');
    setTimeout(() => {
      this.notificationBanner.classList.remove('active');
    }, 3200);
  }

  updateHealth(health) {
    this.heartIcons.forEach((icon, idx) => {
      if (idx < health) {
        icon.classList.remove('lost');
        icon.classList.add('pulse');
      } else {
        icon.classList.add('lost');
        icon.classList.remove('pulse');
      }
    });
    if (health < 3) {
      this.vibrateGamepad(300, 0.8, 0.95);
    }
  }

  startTimer() {
    this.timerSeconds = 0;
    if (this.timerInterval) clearInterval(this.timerInterval);
    this.timerInterval = setInterval(() => {
      if (!this.isPaused) {
        this.timerSeconds++;
        const mins = String(Math.floor(this.timerSeconds / 60)).padStart(2, '0');
        const secs = String(this.timerSeconds % 60).padStart(2, '0');
        this.timerDisplay.textContent = `${mins}:${secs}`;
      }
    }, 1000);
  }

  togglePause() {
    this.isPaused = !this.isPaused;
    if (this.isPaused) {
      this.pauseModal.classList.add('active');
    } else {
      this.pauseModal.classList.remove('active');
    }
  }

  toggleQuestModal() {
    const isActive = this.questModal.classList.contains('active');
    if (isActive) {
      this.questModal.classList.remove('active');
    } else {
      this.renderMissionsList();
      this.questModal.classList.add('active');
    }
  }

  toggleSettingsModal() {
    const isActive = this.settingsModal.classList.contains('active');
    if (isActive) {
      this.settingsModal.classList.remove('active');
    } else {
      this.settingsModal.classList.add('active');
    }
  }

  showVictory() {
    const mins = String(Math.floor(this.timerSeconds / 60)).padStart(2, '0');
    const secs = String(this.timerSeconds % 60).padStart(2, '0');
    document.getElementById('victory-time').textContent = `${mins}:${secs}`;
    document.getElementById('victory-coins').textContent = this.coinsCount.textContent;
    this.victoryModal.classList.add('active');
  }

  consumeInput() {
    const input = { ...this.inputState };
    this.inputState.jumpPressed = false;
    this.inputState.divePressed = false;
    this.inputState.poundPressed = false;
    return input;
  }
}

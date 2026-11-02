export class SoundManager {
  constructor() {
    this.audioContext = null;
    this.soundsEnabled = false;
    this.initialized = false;
    this.volume = 0.3;
    
    // Throttling for frequent sounds (milliseconds)
    this.soundThrottles = {
      SHOOT: 50,        // Max once per 50ms
      EXPLOSION: 30,    // Max once per 30ms
      COMBO: 100,       // Max once per 100ms
      BOSS_HIT: 50      // Max once per 50ms
    };
    
    // Last play times for throttling
    this.lastPlayTimes = {};
    
    // Max concurrent sounds per type
    this.maxConcurrentSounds = {
      SHOOT: 3,
      EXPLOSION: 2,
      COMBO: 1,
      BOSS_HIT: 2
    };
    
    // Active sound count per type
    this.activeSoundCounts = {};
    
    this.soundTypes = {
      SHOOT: 'shoot',
      EXPLOSION: 'explosion',
      PICKUP: 'pickup',
      POWERUP: 'powerup',
      LEVEL_UP: 'levelUp',
      DAMAGE: 'damage',
      BOSS_HIT: 'bossHit',
      BOSS_KILL: 'bossKill',
      COMBO: 'combo'
    };
  }
  
  init() {
    if (this.initialized) return;
    this.initialized = true;
  }
  
  ensureAudioContext() {
    if (!this.audioContext) {
      try {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      } catch (e) {
        console.warn('AudioContext not supported:', e);
        this.soundsEnabled = false;
        return false;
      }
    }
    
    if (this.audioContext.state === 'suspended') {
      this.audioContext.resume().catch(e => {
        console.warn('Failed to resume AudioContext:', e);
      });
    }
    
    return true;
  }
  
  resume() {
    if (this.audioContext && this.audioContext.state === 'suspended') {
      this.audioContext.resume().catch(e => {
        console.warn('Failed to resume AudioContext:', e);
      });
    }
  }
  
  playSound(type, options = {}) {
    if (!this.soundsEnabled || !this.initialized) return;
    
    if (!this.ensureAudioContext()) return;
    
    if (this.audioContext.state === 'suspended') {
      this.resume();
      return;
    }
    
    // Check throttling
    const throttle = this.soundThrottles[type];
    if (throttle) {
      const now = Date.now();
      const lastPlayTime = this.lastPlayTimes[type] || 0;
      if (now - lastPlayTime < throttle) {
        return; // Skip sound due to throttling
      }
      this.lastPlayTimes[type] = now;
    }
    
    // Check max concurrent sounds
    const maxConcurrent = this.maxConcurrentSounds[type];
    if (maxConcurrent) {
      const activeCount = this.activeSoundCounts[type] || 0;
      if (activeCount >= maxConcurrent) {
        return; // Skip sound due to max concurrent limit
      }
    }
    
    const volume = options.volume !== undefined ? options.volume : this.volume;
    
    // Increment active count if needed
    if (maxConcurrent) {
      this.activeSoundCounts[type] = (this.activeSoundCounts[type] || 0) + 1;
    }
    
    // Create callback to decrement count when sound finishes
    const onSoundEnd = () => {
      if (maxConcurrent && this.activeSoundCounts[type] > 0) {
        this.activeSoundCounts[type]--;
      }
    };
    
    switch (type) {
      case this.soundTypes.SHOOT:
        this.playShootSound(volume, onSoundEnd);
        break;
      case this.soundTypes.EXPLOSION:
        this.playExplosionSound(volume, onSoundEnd);
        break;
      case this.soundTypes.PICKUP:
        this.playPickupSound(volume, onSoundEnd);
        break;
      case this.soundTypes.POWERUP:
        this.playPowerupSound(volume, onSoundEnd);
        break;
      case this.soundTypes.LEVEL_UP:
        this.playLevelUpSound(volume, onSoundEnd);
        break;
      case this.soundTypes.DAMAGE:
        this.playDamageSound(volume, onSoundEnd);
        break;
      case this.soundTypes.BOSS_HIT:
        this.playBossHitSound(volume, onSoundEnd);
        break;
      case this.soundTypes.BOSS_KILL:
        this.playBossKillSound(volume, onSoundEnd);
        break;
      case this.soundTypes.COMBO:
        this.playComboSound(volume, onSoundEnd);
        break;
    }
  }
  
  playShootSound(volume, onEnd = null) {
    const oscillator = this.audioContext.createOscillator();
    const gainNode = this.audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(this.audioContext.destination);
    
    oscillator.type = 'square';
    oscillator.frequency.setValueAtTime(800, this.audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(400, this.audioContext.currentTime + 0.05);
    
    gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume * 0.3, this.audioContext.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.05);
    
    if (onEnd) {
      oscillator.addEventListener('ended', onEnd);
    }
    
    oscillator.start(this.audioContext.currentTime);
    oscillator.stop(this.audioContext.currentTime + 0.05);
  }
  
  playExplosionSound(volume, onEnd = null) {
    const oscillator = this.audioContext.createOscillator();
    const gainNode = this.audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(this.audioContext.destination);
    
    oscillator.type = 'sawtooth';
    oscillator.frequency.setValueAtTime(150, this.audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(50, this.audioContext.currentTime + 0.2);
    
    gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume * 0.4, this.audioContext.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.2);
    
    if (onEnd) {
      oscillator.addEventListener('ended', onEnd);
    }
    
    oscillator.start(this.audioContext.currentTime);
    oscillator.stop(this.audioContext.currentTime + 0.2);
  }
  
  playPickupSound(volume, onEnd = null) {
    const oscillator = this.audioContext.createOscillator();
    const gainNode = this.audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(this.audioContext.destination);
    
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(600, this.audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(800, this.audioContext.currentTime + 0.1);
    
    gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume * 0.25, this.audioContext.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.1);
    
    if (onEnd) {
      oscillator.addEventListener('ended', onEnd);
    }
    
    oscillator.start(this.audioContext.currentTime);
    oscillator.stop(this.audioContext.currentTime + 0.1);
  }
  
  playPowerupSound(volume, onEnd = null) {
    const oscillator1 = this.audioContext.createOscillator();
    const oscillator2 = this.audioContext.createOscillator();
    const gainNode = this.audioContext.createGain();
    
    oscillator1.connect(gainNode);
    oscillator2.connect(gainNode);
    gainNode.connect(this.audioContext.destination);
    
    oscillator1.type = 'sine';
    oscillator1.frequency.setValueAtTime(400, this.audioContext.currentTime);
    oscillator1.frequency.exponentialRampToValueAtTime(600, this.audioContext.currentTime + 0.15);
    
    oscillator2.type = 'sine';
    oscillator2.frequency.setValueAtTime(600, this.audioContext.currentTime);
    oscillator2.frequency.exponentialRampToValueAtTime(800, this.audioContext.currentTime + 0.15);
    
    gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume * 0.3, this.audioContext.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.15);
    
    let endedCount = 0;
    const checkEnd = () => {
      endedCount++;
      if (endedCount === 2 && onEnd) {
        onEnd();
      }
    };
    
    oscillator1.addEventListener('ended', checkEnd);
    oscillator2.addEventListener('ended', checkEnd);
    
    oscillator1.start(this.audioContext.currentTime);
    oscillator2.start(this.audioContext.currentTime);
    oscillator1.stop(this.audioContext.currentTime + 0.15);
    oscillator2.stop(this.audioContext.currentTime + 0.15);
  }
  
  playLevelUpSound(volume, onEnd = null) {
    const time = this.audioContext.currentTime;
    
    for (let i = 0; i < 3; i++) {
      const oscillator = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(this.audioContext.destination);
      
      oscillator.type = 'sine';
      const freq = 400 + i * 200;
      oscillator.frequency.setValueAtTime(freq, time + i * 0.1);
      
      gainNode.gain.setValueAtTime(0, time + i * 0.1);
      gainNode.gain.linearRampToValueAtTime(volume * 0.3, time + i * 0.1 + 0.01);
      gainNode.gain.exponentialRampToValueAtTime(0.01, time + i * 0.1 + 0.1);
      
      if (i === 2 && onEnd) {
        oscillator.addEventListener('ended', onEnd);
      }
      
      oscillator.start(time + i * 0.1);
      oscillator.stop(time + i * 0.1 + 0.1);
    }
  }
  
  playDamageSound(volume, onEnd = null) {
    const oscillator = this.audioContext.createOscillator();
    const gainNode = this.audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(this.audioContext.destination);
    
    oscillator.type = 'square';
    oscillator.frequency.setValueAtTime(200, this.audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(100, this.audioContext.currentTime + 0.15);
    
    gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume * 0.4, this.audioContext.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.15);
    
    if (onEnd) {
      oscillator.addEventListener('ended', onEnd);
    }
    
    oscillator.start(this.audioContext.currentTime);
    oscillator.stop(this.audioContext.currentTime + 0.15);
  }
  
  playBossHitSound(volume, onEnd = null) {
    const oscillator = this.audioContext.createOscillator();
    const gainNode = this.audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(this.audioContext.destination);
    
    oscillator.type = 'sawtooth';
    oscillator.frequency.setValueAtTime(300, this.audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(200, this.audioContext.currentTime + 0.1);
    
    gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume * 0.35, this.audioContext.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.1);
    
    if (onEnd) {
      oscillator.addEventListener('ended', onEnd);
    }
    
    oscillator.start(this.audioContext.currentTime);
    oscillator.stop(this.audioContext.currentTime + 0.1);
  }
  
  playBossKillSound(volume, onEnd = null) {
    const time = this.audioContext.currentTime;
    
    for (let i = 0; i < 5; i++) {
      const oscillator = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(this.audioContext.destination);
      
      oscillator.type = 'sine';
      const freq = 200 + i * 100;
      oscillator.frequency.setValueAtTime(freq, time + i * 0.05);
      
      gainNode.gain.setValueAtTime(0, time + i * 0.05);
      gainNode.gain.linearRampToValueAtTime(volume * 0.3, time + i * 0.05 + 0.01);
      gainNode.gain.exponentialRampToValueAtTime(0.01, time + i * 0.05 + 0.1);
      
      if (i === 4 && onEnd) {
        oscillator.addEventListener('ended', onEnd);
      }
      
      oscillator.start(time + i * 0.05);
      oscillator.stop(time + i * 0.05 + 0.1);
    }
  }
  
  playComboSound(volume, onEnd = null) {
    const oscillator = this.audioContext.createOscillator();
    const gainNode = this.audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(this.audioContext.destination);
    
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(500, this.audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(700, this.audioContext.currentTime + 0.08);
    
    gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume * 0.25, this.audioContext.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.08);
    
    if (onEnd) {
      oscillator.addEventListener('ended', onEnd);
    }
    
    oscillator.start(this.audioContext.currentTime);
    oscillator.stop(this.audioContext.currentTime + 0.08);
  }
  
  setEnabled(enabled) {
    this.soundsEnabled = enabled;
  }
  
  setVolume(volume) {
    this.volume = Math.max(0, Math.min(1, volume));
  }
}


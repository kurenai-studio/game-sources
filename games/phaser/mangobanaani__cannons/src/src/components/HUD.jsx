import React from 'react';

const styles = {
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    width: 800,
    height: 600,
    pointerEvents: 'none',
    fontFamily: 'monospace',
    color: '#333',
  },
  topBar: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    padding: '8px 12px',
  },
  hpSection: {
    display: 'flex',
    flexDirection: 'column',
    gap: 4,
  },
  hpLabel: {
    fontSize: 12,
    fontWeight: 'bold',
  },
  hpBarOuter: {
    width: 120,
    height: 10,
    backgroundColor: '#333',
    borderRadius: 2,
  },
  hpBarInner: (pct, isPlayer) => ({
    width: `${pct}%`,
    height: '100%',
    backgroundColor: pct > 50 ? '#00cc00' : pct > 25 ? '#cccc00' : '#cc0000',
    borderRadius: 2,
    transition: 'width 0.3s',
  }),
  windSection: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: 2,
  },
  windLabel: {
    fontSize: 12,
    fontWeight: 'bold',
  },
  windValue: {
    fontSize: 16,
  },
  windArrow: (wind) => ({
    fontSize: 20,
    transform: wind > 0 ? 'scaleX(1)' : 'scaleX(-1)',
    opacity: Math.min(Math.abs(wind) / 3, 1),
  }),
  bottomBar: {
    position: 'absolute',
    bottom: 8,
    left: 0,
    width: '100%',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    padding: '0 12px',
  },
  aimSection: {
    fontSize: 14,
  },
  weaponSection: {
    display: 'flex',
    gap: 6,
  },
  weaponSlot: (active) => ({
    fontSize: 12,
    padding: '4px 8px',
    border: `2px solid ${active ? '#333' : '#999'}`,
    borderRadius: 3,
    backgroundColor: active ? '#333' : 'rgba(255,255,255,0.7)',
    color: active ? '#fff' : '#333',
  }),
  cooldownOuter: {
    position: 'absolute',
    bottom: 40,
    left: 12,
    width: 120,
    height: 6,
    backgroundColor: 'rgba(0,0,0,0.3)',
    borderRadius: 3,
  },
  cooldownInner: (pct) => ({
    width: `${pct}%`,
    height: '100%',
    backgroundColor: pct >= 100 ? '#00cc00' : '#ff9900',
    borderRadius: 3,
    transition: 'width 0.1s',
  }),
  roundInfo: {
    position: 'absolute',
    top: 8,
    left: '50%',
    transform: 'translateX(-50%)',
    fontSize: 14,
    fontWeight: 'bold',
  },
};

const WEAPON_LABELS = ['STD', 'BIG', 'CLU'];

export default function HUD({ data }) {
  if (!data) return null;

  const {
    playerHp = 100,
    aiHp = 100,
    wind = 0,
    cooldownPct = 100,
    weaponIndex = 0,
    round = 1,
    playerScore = 0,
    aiScore = 0,
    angle = 45,
    power = 8,
    aiName = 'Enemy',
  } = data;

  const windDisplay = Math.abs(wind).toFixed(1);
  const windDir = wind === 0 ? '--' : wind > 0 ? '>>>' : '<<<';

  return (
    <div style={styles.overlay}>
      <div style={styles.topBar}>
        <div style={styles.hpSection}>
          <span style={styles.hpLabel}>YOU</span>
          <div style={styles.hpBarOuter}>
            <div style={styles.hpBarInner(playerHp, true)} />
          </div>
        </div>

        <div style={styles.windSection}>
          <span style={styles.windLabel}>WIND</span>
          <span style={styles.windValue}>{windDir} {windDisplay}</span>
        </div>

        <div style={styles.hpSection}>
          <span style={{ ...styles.hpLabel, textAlign: 'right' }}>{aiName}</span>
          <div style={styles.hpBarOuter}>
            <div style={styles.hpBarInner(aiHp, false)} />
          </div>
        </div>
      </div>

      <div style={styles.roundInfo}>
        Round {round} | {playerScore} - {aiScore}
      </div>

      <div style={styles.cooldownOuter}>
        <div style={styles.cooldownInner(cooldownPct)} />
      </div>

      <div style={styles.bottomBar}>
        <div style={styles.aimSection}>
          Angle: {angle} | Power: {power.toFixed(1)}
        </div>

        <div style={styles.weaponSection}>
          {WEAPON_LABELS.map((label, i) => (
            <div key={i} style={styles.weaponSlot(i === weaponIndex)}>
              {i + 1}:{label}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

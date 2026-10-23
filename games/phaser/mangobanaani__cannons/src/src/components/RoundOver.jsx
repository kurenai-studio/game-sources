import React from 'react';

const styles = {
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    width: 800,
    height: 600,
    backgroundColor: 'rgba(0,0,0,0.6)',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    fontFamily: 'monospace',
    color: '#fff',
    zIndex: 10,
  },
  title: {
    fontSize: 48,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  score: {
    fontSize: 24,
    marginBottom: 8,
  },
  detail: {
    fontSize: 16,
    color: '#ccc',
    marginBottom: 30,
  },
  button: {
    fontSize: 20,
    fontFamily: 'monospace',
    padding: '10px 24px',
    border: '2px solid #fff',
    borderRadius: 4,
    cursor: 'pointer',
    backgroundColor: 'transparent',
    color: '#fff',
    pointerEvents: 'auto',
  },
};

export default function RoundOver({ data, onNextRound }) {
  if (!data) return null;

  const { winner, playerScore, aiScore, round } = data;
  const playerWonRound = winner === 'player';

  return (
    <div style={styles.overlay}>
      <div style={{
        ...styles.title,
        color: playerWonRound ? '#88ff88' : '#ff8888',
      }}>
        {playerWonRound ? 'ROUND WON' : 'ROUND LOST'}
      </div>
      <div style={styles.score}>
        Score: {playerScore} - {aiScore}
      </div>
      <div style={styles.detail}>Round {round} complete</div>
      <button
        style={styles.button}
        onClick={onNextRound}
        onMouseEnter={(e) => {
          e.target.style.backgroundColor = 'rgba(255,255,255,0.2)';
        }}
        onMouseLeave={(e) => {
          e.target.style.backgroundColor = 'transparent';
        }}
      >
        [ NEXT ROUND ]
      </button>
    </div>
  );
}

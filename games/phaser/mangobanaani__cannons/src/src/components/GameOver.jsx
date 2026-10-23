import React from 'react';

const styles = {
  container: {
    width: 800,
    height: 600,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    fontFamily: 'monospace',
  },
  title: {
    fontSize: 64,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  subtitle: {
    fontSize: 18,
    marginBottom: 8,
  },
  score: {
    fontSize: 24,
    marginBottom: 40,
  },
  button: {
    fontSize: 24,
    fontFamily: 'monospace',
    padding: '10px 30px',
    border: 'none',
    borderRadius: 4,
    cursor: 'pointer',
    backgroundColor: '#fff',
    color: '#333',
    marginBottom: 12,
  },
  menuButton: {
    fontSize: 18,
    fontFamily: 'monospace',
    padding: '8px 20px',
    border: 'none',
    borderRadius: 4,
    cursor: 'pointer',
    backgroundColor: 'transparent',
    color: '#666',
  },
};

export default function GameOver({ data, onPlayAgain, onMainMenu }) {
  if (!data) return null;

  const { playerWon, playerScore, aiScore } = data;
  const bgColor = playerWon ? '#d4edda' : '#f8d7da';
  const textColor = playerWon ? '#155724' : '#721c24';

  return (
    <div style={{ ...styles.container, backgroundColor: bgColor }}>
      <div style={{ ...styles.title, color: textColor }}>
        {playerWon ? 'VICTORY' : 'DEFEAT'}
      </div>
      <div style={{ ...styles.subtitle, color: textColor }}>
        {playerWon ? 'You destroyed the enemy cannon!' : 'Your cannon was destroyed!'}
      </div>
      <div style={{ ...styles.score, color: textColor }}>
        Final Score: {playerScore} - {aiScore}
      </div>
      <button
        style={styles.button}
        onClick={onPlayAgain}
        onMouseEnter={(e) => { e.target.style.color = '#3366cc'; }}
        onMouseLeave={(e) => { e.target.style.color = '#333'; }}
      >
        [ PLAY AGAIN ]
      </button>
      <button
        style={styles.menuButton}
        onClick={onMainMenu}
        onMouseEnter={(e) => { e.target.style.color = '#3366cc'; }}
        onMouseLeave={(e) => { e.target.style.color = '#666'; }}
      >
        [ MAIN MENU ]
      </button>
    </div>
  );
}

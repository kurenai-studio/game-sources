import React, { useState } from 'react';

const styles = {
  container: {
    width: 800,
    height: 600,
    backgroundColor: '#87CEEB',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    fontFamily: 'monospace',
    color: '#333',
  },
  title: {
    fontSize: 64,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  subtitle: {
    fontSize: 18,
    color: '#555',
    marginBottom: 40,
  },
  difficultySection: {
    display: 'flex',
    gap: 12,
    marginBottom: 30,
  },
  diffButton: (selected) => ({
    fontSize: 16,
    fontFamily: 'monospace',
    padding: '8px 20px',
    border: '2px solid #333',
    borderRadius: 4,
    cursor: 'pointer',
    backgroundColor: selected ? '#333' : '#fff',
    color: selected ? '#fff' : '#333',
  }),
  startButton: {
    fontSize: 24,
    fontFamily: 'monospace',
    padding: '10px 30px',
    border: 'none',
    borderRadius: 4,
    cursor: 'pointer',
    backgroundColor: '#fff',
    color: '#333',
    marginBottom: 40,
  },
  controls: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    lineHeight: 1.8,
  },
};

const DIFFICULTIES = [
  { key: 'easy', label: 'Easy' },
  { key: 'medium', label: 'Medium' },
  { key: 'hard', label: 'Hard' },
];

export default function Menu({ onStart }) {
  const [difficulty, setDifficulty] = useState('medium');

  return (
    <div style={styles.container}>
      <div style={styles.title}>CANNONS</div>
      <div style={styles.subtitle}>Destroy the enemy cannon!</div>

      <div style={styles.difficultySection}>
        {DIFFICULTIES.map((d) => (
          <button
            key={d.key}
            style={styles.diffButton(difficulty === d.key)}
            onClick={() => setDifficulty(d.key)}
          >
            {d.label}
          </button>
        ))}
      </div>

      <button
        style={styles.startButton}
        onClick={() => onStart(difficulty)}
        onMouseEnter={(e) => { e.target.style.color = '#3366cc'; }}
        onMouseLeave={(e) => { e.target.style.color = '#333'; }}
      >
        [ START GAME ]
      </button>

      <div style={styles.controls}>
        Controls:<br />
        UP/DOWN - Adjust angle<br />
        LEFT/RIGHT - Adjust power<br />
        SPACE - Fire<br />
        1/2/3 - Switch weapon
      </div>
    </div>
  );
}

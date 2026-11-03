using System;

namespace DungeonExplorer.Core
{
    /// <summary>
    /// Gestisce lo stato generale del gioco, punteggi e statistiche
    /// </summary>
    public class GameManager
    {
        public int Score { get; set; }
        public int TreasuresCollected { get; set; }
        public int EnemiesDefeated { get; set; }
        public int CurrentLevel { get; set; }
        public TimeSpan PlayTime { get; set; }
        
        public event Action<int> ScoreChanged;
        public event Action<int> TreasureCollected;
        public event Action<int> EnemyDefeated;
        public event Action<int> LevelChanged;

        public GameManager()
        {
            Reset();
        }

        /// <summary>
        /// Resetta tutti i valori del gioco
        /// </summary>
        public void Reset()
        {
            Score = 0;
            TreasuresCollected = 0;
            EnemiesDefeated = 0;
            CurrentLevel = 1;
            PlayTime = TimeSpan.Zero;
        }

        /// <summary>
        /// Aggiunge punti al punteggio
        /// </summary>
        public void AddScore(int points)
        {
            Score += points;
            ScoreChanged?.Invoke(Score);
        }

        /// <summary>
        /// Registra la raccolta di un tesoro
        /// </summary>
        public void CollectTreasure(int value = 100)
        {
            TreasuresCollected++;
            AddScore(value);
            TreasureCollected?.Invoke(TreasuresCollected);
        }

        /// <summary>
        /// Registra l'eliminazione di un nemico
        /// </summary>
        public void DefeatEnemy(int points = 50)
        {
            EnemiesDefeated++;
            AddScore(points);
            EnemyDefeated?.Invoke(EnemiesDefeated);
        }

        /// <summary>
        /// Avanza al livello successivo
        /// </summary>
        public void NextLevel()
        {
            CurrentLevel++;
            AddScore(CurrentLevel * 200); // Bonus per completare il livello
            LevelChanged?.Invoke(CurrentLevel);
        }

        /// <summary>
        /// Aggiorna il tempo di gioco
        /// </summary>
        public void UpdatePlayTime(TimeSpan deltaTime)
        {
            PlayTime = PlayTime.Add(deltaTime);
        }

        /// <summary>
        /// Calcola il punteggio finale considerando vari fattori
        /// </summary>
        public int CalculateFinalScore()
        {
            int timeBonus = Math.Max(0, 10000 - (int)PlayTime.TotalSeconds * 10);
            int treasureBonus = TreasuresCollected * 150;
            int enemyBonus = EnemiesDefeated * 75;
            int levelBonus = CurrentLevel * 500;
            
            return Score + timeBonus + treasureBonus + enemyBonus + levelBonus;
        }

        /// <summary>
        /// Ottiene statistiche di gioco formattate
        /// </summary>
        public string GetFormattedStats()
        {
            return $"Level: {CurrentLevel} | Score: {Score:N0} | " +
                   $"Treasures: {TreasuresCollected} | Enemies: {EnemiesDefeated} | " +
                   $"Time: {PlayTime:mm\\:ss}";
        }
    }
}
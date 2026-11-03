using Microsoft.Xna.Framework;
using System.Collections.Generic;

namespace DungeonExplorer.Data
{
    /// <summary>
    /// Contiene i dati necessari per salvare e caricare una partita.
    /// </summary>
    public class GameData
    {
        public Vector2 PlayerPosition { get; set; }
        public int PlayerHealth { get; set; }
        public int Score { get; set; }
        public int TreasuresCollected { get; set; }
        public int DungeonSeed { get; set; }
        public List<Vector2> EnemyPositions { get; set; }
        public List<Vector2> TreasurePositions { get; set; }

        public GameData()
        {
            EnemyPositions = new List<Vector2>();
            TreasurePositions = new List<Vector2>();
        }
    }
}
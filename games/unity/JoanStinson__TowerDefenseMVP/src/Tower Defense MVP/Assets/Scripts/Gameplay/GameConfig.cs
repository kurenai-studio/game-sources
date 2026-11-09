using JGM.Gameplay.Turrets.Projectiles;
using JGM.Gameplay.Waves;
using UnityEngine;

namespace JGM.Gameplay
{
    [CreateAssetMenu(fileName = "New Game Config", menuName = "Game Config")]
    public class GameConfig : ScriptableObject
    {
        public WaveList WaveList;
        public ProjectilePoolConfig ProjectilePoolConfig;
        public int PlayerStartHealth = 30;
        public int PlayerStartCoins = 50;
    }
}

using UnityEngine;

namespace JGM.Gameplay.Waves
{
    [CreateAssetMenu(fileName = "New Wave List", menuName = "Waves/Wave List")]
    public class WaveList : ScriptableObject
    {
        public Wave[] Waves;
    }
}

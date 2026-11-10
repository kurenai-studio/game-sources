using AnatomyJam.Material;
using AnatomyJam.Util;
using UnityEngine;

namespace AnatomyJam.SO
{
    /// <summary>
    /// Represent a zone the character are going through on the 2D view
    /// Party go to the next zone once they beat the boss of the current one
    /// </summary>
    [CreateAssetMenu(menuName = "ScriptableObject/MapZone", fileName = "MapZone")]
    public class MapZone : ScriptableObject
    {
        [Tooltip("Name of the zone")]
        public string Name;

        [Tooltip("Enemies the party can encounter in this zone")]
        public CharacterInfo[] Encounters;

        [Tooltip("The boss the player will encounter between switching to new zone")]
        public CharacterInfo Boss;

        [Tooltip("Resources unlocked once the zone is completed")]
        public ResourceType[] UnlockedResources;

        [Tooltip("Number of enemies before the party reach the boss")]
        public Range<int> NbOfEnemiesBeforeBoss;

        [Header("Sprite data")]

        public Sprite[] _spriteGrass, _spritePath, _spritePathLeft, _spritePathRight;
    }
}

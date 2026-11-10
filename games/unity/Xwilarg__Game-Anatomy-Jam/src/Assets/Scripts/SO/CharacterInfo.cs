using AnatomyJam.Util;
using UnityEngine;

namespace AnatomyJam.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/CharacterInfo", fileName = "CharacterInfo")]
    public class CharacterInfo : ScriptableObject
    {
        [Tooltip("Name of the character")]
        public string Name;

        [Header("Stats")]
        [Tooltip("Health of the character")]
        public int BaseHealth;
        [Tooltip("Mana of the character, used for special attacks")]
        public int BaseMana;

        [Tooltip("Natural armor of the character, damage are substracted by it")]
        public int BaseArmor;
        [Tooltip("Base damage")]
        public Range<int> BaseAttack;

        [Tooltip("Time between 2 attacks in seconds")]
        public Range<float> AttackSpeed;

        [Tooltip("Class of the character")]
        public CharacterClass Class;
        [Tooltip("Does character target its allie of enemy when attacking? (Healer \"attack\" their allie)")]
        public TargetType TargetType;

        [Tooltip("For enemy only, sprite")]
        public Sprite EnemySprite;
    }
}

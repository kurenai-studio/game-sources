using UnityEngine;

namespace LudumDare57.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/MapGenInfo", fileName = "MapGenInfo")]
    public class MapGenInfo : ScriptableObject
    {
        public int MapGenWidth;
        public LevelSpawnInfo[] AreaInfo;
        public int AreaHeight;
        public int AreaInterSpacing;

        public Range<float> EnemyReactionTime;
        public float GoldChance;
    }

    [System.Serializable]
    public record Range<T>
    {
        public T Min;
        public T Max;
    }

    [System.Serializable]
    public record LevelSpawnInfo
    {
        public Range<int> CorruptedAmount;
        public Range<int> TotalAmount;
    }
}
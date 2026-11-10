using UnityEngine;

namespace LudumDare57.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/TileInfo", fileName = "TileInfo")]
    public class TileInfo : ScriptableObject
    {
        public Sprite[] Sprites;

        public bool IsOnTop;
        public bool IsDestructible;
        public bool IsValuable;
        public bool IsObjective;
    }
}
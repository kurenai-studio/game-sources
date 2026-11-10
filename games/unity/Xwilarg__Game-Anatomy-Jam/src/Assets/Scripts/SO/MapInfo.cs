using UnityEngine;

namespace AnatomyJam.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/MapInfo", fileName = "MapInfo")]
    public class MapInfo : ScriptableObject
    {
        [Tooltip("Size of the pixel of a tile")]
        public float PixelSize;

        [Tooltip("Number of line a group of tile contain")]
        public int NbOfLines;

        [Tooltip("Scrolling speed")]
        public float ScrollingSpeed;

        [Tooltip("Y value before object is moved on top")]
        public float MinBeforeReset;
    }
}

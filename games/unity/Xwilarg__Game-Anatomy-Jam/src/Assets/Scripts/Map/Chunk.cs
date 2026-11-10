using AnatomyJam.SO;
using UnityEngine;

namespace AnatomyJam.Map
{
    public class Chunk : MonoBehaviour
    {
        [SerializeField]
        private RowData[] _data;

        public void SetZone(MapZone zone)
        {
            foreach (var e in _data)
            {
                e.SetZone(zone);
            }
        }
    }
}

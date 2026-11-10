using AnatomyJam.Manager;
using AnatomyJam.SO;
using UnityEngine;

namespace AnatomyJam.Map
{
    public class MapScroller : MonoBehaviour
    {
        public static MapScroller S;

        private void Awake()
        {
            S = this;
        }

        [SerializeField]
        private Chunk[] _background;

        [SerializeField]
        private MapInfo _mapInfo;

        public bool IsScrolling { private get; set; } = false;

        private void FixedUpdate()
        {
            if (IsScrolling)
            {
                foreach (var t in _background)
                {
                    t.transform.Translate(Vector2.down * _mapInfo.ScrollingSpeed);
                    if (t.transform.position.y < _mapInfo.MinBeforeReset)
                    {
                        t.transform.position = new(t.transform.position.x, t.transform.position.y + (_background.Length * _mapInfo.PixelSize * _mapInfo.NbOfLines), t.transform.position.z);
                        t.SetZone(ProgressManager.S.CurrentZone);
                    }
                }
            }
        }

        public void ResetAll(MapZone zone)
        {
            foreach (var chunk in _background)
            {
                chunk.SetZone(zone);
            }
        }
    }
}

using AnatomyJam.SO;
using UnityEngine;

namespace AnatomyJam.Map
{
    public class RowData : MonoBehaviour
    {
        [SerializeField]
        private SpriteRenderer[] _grass, _path, _pathLeft, _pathRight;

        public void SetZone(MapZone zone)
        {
            foreach (var e in _grass)
            {
                e.sprite = zone._spriteGrass[Random.Range(0, zone._spriteGrass.Length)];
            }
            foreach (var e in _path)
            {
                e.sprite = zone._spritePath[Random.Range(0, zone._spritePath.Length)];
            }
            foreach (var e in _pathLeft)
            {
                e.sprite = zone._spritePathLeft[Random.Range(0, zone._spritePathLeft.Length)];
            }
            foreach (var e in _pathRight)
            {
                e.sprite = zone._spritePathRight[Random.Range(0, zone._spritePathRight.Length)];
            }
        }
    }
}

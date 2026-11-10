using UnityEngine;

namespace LD55
{
    public class Ingredient : MonoBehaviour
    {
        #region Inspector

        [SerializeField] Color _Color = Color.white;

        #endregion

        public Color color
        {
            get => _Color;
            set
            {
                _Color = value;
                UpdateColor();
            }
        }

        void Start()
        {
            UpdateColor();
        }

        void UpdateColor()
        {
            var renderer = GetComponentInChildren<Renderer>();
            renderer.material.color = _Color;
        }

        public void Consume()
        {
            gameObject.SetActive(false);
        }

        void OnTriggerEnter(Collider other)
        {
            if (other.GetComponentInParent<Player>() is Player player)
            {
                player.OnEnter(this);
            }
        }
    }
}

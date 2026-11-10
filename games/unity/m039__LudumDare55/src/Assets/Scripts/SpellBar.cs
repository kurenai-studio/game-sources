using UnityEngine;

namespace LD55
{
    public class SpellBar : MonoBehaviour
    {
        #region Inspector

        [SerializeField] RectTransform _Main;

        #endregion

        RectTransform _root;

        RectTransform _rootParent;

        float _value = 0f;

        Transform _location;

        RectTransform Root
        {
            get
            {
                if (_root == null)
                {
                    _root = GetComponent<RectTransform>();
                }

                return _root;
            }
        }

        RectTransform RootParent
        {
            get
            {
                if (_rootParent == null)
                {
                    _rootParent = transform.parent.GetComponent<RectTransform>();
                }

                return _rootParent;
            }
        }

        public float Value
        {
            get
            {
                return _value;
            }

            set
            {
                _value = Mathf.Clamp01(value);
                UpdateVisual();
            }
        }

        public void Attach(Transform spellBarLocation)
        {
            _location = spellBarLocation;
        }

        void LateUpdate()
        {
            ProcessLocation();
        }

        void UpdateVisual()
        {
            var size = Root.sizeDelta;
            var offsetMax = _Main.offsetMax;
            offsetMax.x = -size.x * (1 - Value);
            _Main.offsetMax = offsetMax;
        }

        void ProcessLocation()
        {
            if (_location == null)
            {
                return;
            }

            var screenPoint = Camera.main.WorldToScreenPoint(_location.position);
            RectTransformUtility.ScreenPointToLocalPointInRectangle(RootParent, screenPoint, null, out Vector2 localPoint);
            transform.localPosition = localPoint;
        }
    }
}

using UnityEngine;

namespace Minigame
{
    public class BarTranslation : MonoBehaviour
    {
        private RectTransform _rect;

        private float _offset;

        [SerializeField]
        private RectTransform _canvas;

        [SerializeField]
        private RectTransform _hitbox;

        [SerializeField]
        private AnimationCurve _curve;

        private void Start()
        {
            _rect = (RectTransform)transform;
            _offset = _canvas.sizeDelta.x / 20f;
        }

        private void FixedUpdate()
        {
            var lengthCanvas = _canvas.sizeDelta.x / 2f;
            var curveEffct = _curve.Evaluate(Random.Range(0.0F, 1.0F));

            if (_rect.localPosition.x - (_rect.sizeDelta.x / 2f) <= -1f * lengthCanvas)
            {
                _offset = (lengthCanvas * (curveEffct * 3f)) / 40f;
            }
            else if (_rect.localPosition.x + (_rect.sizeDelta.x / 2f) >= lengthCanvas)
            {
                _offset = ((lengthCanvas * (curveEffct * 3f) / 40f) * -1f);
            }

            _rect.localPosition = new(
                _rect.localPosition.x + _offset,
                _rect.localPosition.y
            );
        }
    }
}

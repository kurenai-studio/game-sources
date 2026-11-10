using UnityEngine;
using UnityEngine.UI;

namespace AnatomyJam.Manager
{
    public class Fade<T> : MonoBehaviour
        where T : MaskableGraphic
    {
        private float _refTime;
        private float _timerFade = -1f;
        private bool _doesFadeDown;

        private T _comp;

        public void LaunchFade(float refTime, bool doesFadeDown)
        {
            _refTime = refTime;
            _timerFade = refTime;
            _doesFadeDown = doesFadeDown;
        }

        private void Awake()
        {
            _comp = GetComponent<T>();
        }

        private void Update()
        {
            if (_timerFade > 0f)
            {
                _timerFade -= Time.deltaTime;
                if (_timerFade < 0f)
                {
                    _timerFade = 0f;
                }
                var percent = _timerFade / _refTime;
                if (_doesFadeDown)
                {
                    percent = 1f - percent;
                }
                _comp.color = new Color(_comp.color.r, _comp.color.g, _comp.color.b, percent);
            }
        }

        public void ResetColor(bool transparent)
        {
            _comp.color = new Color(_comp.color.r, _comp.color.g, _comp.color.b, transparent ? 0f : 1f);
        }
    }
}

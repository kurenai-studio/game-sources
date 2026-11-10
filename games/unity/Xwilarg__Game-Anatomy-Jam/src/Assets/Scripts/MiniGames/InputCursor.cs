using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;
using System.Collections;

namespace Minigame
{
    public class InputCursor : AMiniGameManager
    {
        private RectTransform _rect;

        private int Hits;
        private RectTransform _target;

        private bool _penalty = false;

        [SerializeField]
        private GameObject _targetRect;

        [SerializeField]
        private GameObject _movingRect;

        [SerializeField]
        private int _targetHit = 5;

        private MinigameCallBack _cb_result;

        private AudioSource _source;

        public int GetHits()
        {
            return Hits;
        }

        public void Hit(InputAction.CallbackContext value)
        {
            if (!gameObject.activeSelf)
                return;

            if (value.phase == InputActionPhase.Started && !_penalty)
            {
                var targetXtLeft = _target.localPosition.x - (_target.sizeDelta.x / 2f);
                var targetXtRight = _target.localPosition.x + (_target.sizeDelta.x / 2f);
                if (_source == null)
                {
                    _source = GetComponent<AudioSource>();
                }
                _source.Play();
                if (_rect.localPosition.x >= targetXtLeft && _rect.localPosition.x <= targetXtRight)
                {
                    StartCoroutine(ChangeBackColor());
                    Hits++;
                    if (Hits >= _targetHit)
                    {
                        _cb_result();
                        gameObject.SetActive(false);
                    }
                }
                else
                {
                    StartCoroutine(Penalty());
                }
            }
        }

        public IEnumerator ChangeBackColor()
        {
            _targetRect.GetComponent<Image>().color = new Color(0.2f, 0.2f, 0.2f);
            
            yield return new WaitForSeconds(0.2f);

            _targetRect.GetComponent<Image>().color = Color.white;
        }

        public IEnumerator Penalty()
        {
            _targetRect.GetComponent<Image>().color = new Color(0.811f, 0.027f, 0.133f);
            _penalty = true;

            yield return new WaitForSeconds(1f);

            _targetRect.GetComponent<Image>().color = Color.white;
            _penalty = false;
        }

        public override void RunMinigame(MinigameCallBack cb_result, float difficultyFactor)
        {
            _rect = (RectTransform)_movingRect.transform;
            _target = (RectTransform)_targetRect.transform;
            _cb_result = cb_result;
            Hits = 0;
            base.RunMinigame(cb_result, difficultyFactor);
        }
    }
}

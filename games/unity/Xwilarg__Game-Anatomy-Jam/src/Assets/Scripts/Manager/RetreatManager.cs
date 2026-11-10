using AnatomyJam.SO;
using System;
using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace AnatomyJam.Manager
{
    public class RetreatManager : MonoBehaviour
    {
        public static RetreatManager S;

        private void Awake()
        {
            S = this;
        }

        [SerializeField]
        private RetreatInfo _info;

        [SerializeField]
        private FadeImage _blackFade;

        [SerializeField]
        private FadeText[] _mainText;

        [SerializeField]
        private FadeText _subText, _fadePercentText;

        [SerializeField]
        private TMP_Text _percentText;

        private int _currentRetreatChances = 100;

        private float _timer = -1;
        private int _startChanceNb;


        public void DisplayRetreat(Action _onReset, Action _onDone)
        {
            StartCoroutine(LaunchRetreat(_onReset, _onDone));
        }

        public IEnumerator DisplayFade(Action next)
        {
            _blackFade.LaunchFade(_info.FadeTimeBackground, true);
            yield return new WaitForSeconds(_info.FadeTimeBackground);
            next?.Invoke();
        }

        private IEnumerator LaunchRetreat(Action _onReset, Action _onDone)
        {
            if (UnityEngine.Random.Range(0, 100) > _currentRetreatChances)
            {
                _blackFade.LaunchFade(_info.FadeTimeBackground, true);
                yield return new WaitForSeconds(_info.FadeTimeBackground);

                SceneManager.LoadScene("GameOver", LoadSceneMode.Single);
            }

            _startChanceNb = _currentRetreatChances;
            _currentRetreatChances -= _info.RetreatChanceMinus;

            _blackFade.LaunchFade(_info.FadeTimeBackground, true);
            yield return new WaitForSeconds(_info.FadeTimeBackground);

            _onReset?.Invoke();

            foreach (var mT in _mainText)
            {
                mT.LaunchFade(_info.FadeTimeBackground, true);
                yield return new WaitForSeconds(_info.FadeTimeText);
                yield return new WaitForSeconds(_info.TimeWait);
            }

            _subText.LaunchFade(_info.FadeTimeBackground, true);
            yield return new WaitForSeconds(_info.FadeTimeText);
            yield return new WaitForSeconds(_info.TimeWait / 2f);

            _fadePercentText.ResetColor(false);
            _timer = _info.PercentTimer;
            yield return new WaitForSeconds(_info.PercentTimer);

            _blackFade.LaunchFade(_info.FadeTimeBackground, false);
            foreach (var mT in _mainText)
            {
                mT.LaunchFade(_info.FadeTimeBackground, false);
            }
            _subText.LaunchFade(_info.FadeTimeBackground, false);
            _fadePercentText.LaunchFade(_info.FadeTimeBackground, false);
            yield return new WaitForSeconds(_info.FadeTimeBackground);

            _onDone?.Invoke();
        }

        private void Update()
        {
            if (_timer > 0f)
            {
                _timer -= Time.deltaTime;
                if (_timer < 0f)
                {
                    _timer = 0f;
                }
                var diff = _startChanceNb - _currentRetreatChances;
                var t = _info.PercentTimer - _timer;
                var nb = _startChanceNb - Mathf.RoundToInt(t * diff / _info.PercentTimer);
                _percentText.text = $"{nb}%";
            }
        }
    }
}
using AnatomyJam.Player;
using AnatomyJam.SO;
using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace AnatomyJam.Manager
{
    public class ProgressManager : MonoBehaviour
    {
        public static ProgressManager S;

        private void Awake()
        {
            S = this;
        }

        [SerializeField]
        private MapZone[] _zones;

        // ANIMATION
        [SerializeField]
        private Animator _animWin;

        [SerializeField]
        private GameObject _village2Unlock, _village3Unlock;

        [SerializeField]
        private SO.AnimationInfo _animInfo;

        [SerializeField]
        private AnimatorOverrideController[] _animOverride;

        private int _currentZone;
        private int _currentFight;

        private int _bossNode;

        public MapZone CurrentZone => _zones[_currentZone];

        private void Start()
        {
            InitCurrentZone();
        }

        public void InitCurrentZone()
        {
            var curr = _zones[_currentZone];
            _bossNode = Random.Range(curr.NbOfEnemiesBeforeBoss.Min, curr.NbOfEnemiesBeforeBoss.Max);
            _currentFight = 0;
        }

        public SO.CharacterInfo GetCurrentEnnemy()
        {
            var curr = _zones[_currentZone];
            return _currentFight == _bossNode ? curr.Boss : curr.Encounters[Random.Range(0, curr.Encounters.Length)];
        }

        public void WinFight(System.Action next)
        {
            if (_currentFight == _bossNode)
            {
                _animWin.gameObject.SetActive(true);
                _animWin.runtimeAnimatorController = _animOverride[_currentZone];

                if (_currentZone == 0)
                {
                    _village2Unlock.SetActive(true);
                }
                else if (_currentZone == 1)
                {
                    _village3Unlock.SetActive(true);
                }

                if (_currentZone == 2)
                {
                    next = () =>
                    {
                        StartCoroutine(RetreatManager.S.DisplayFade(() =>
                        {
                            SceneManager.LoadScene("Victory");
                        }));
                    };
                }

                StartCoroutine(WaitAnimEnd(next, _currentZone));
                _currentZone++;

                if (_currentZone < 3)
                {
                    InitCurrentZone();
                }
            }
            else
            {
                _currentFight++;
                next?.Invoke();
            }
        }

        public IEnumerator WaitAnimEnd(System.Action next, int index)
        {
            PlayerController.S.CanMove = false;

            yield return new WaitForSeconds(_animInfo.Duration[index]);
            _animWin.gameObject.SetActive(false);
            next?.Invoke();

            PlayerController.S.CanMove = true;
            _animWin.gameObject.SetActive(false);
        }
    }
}

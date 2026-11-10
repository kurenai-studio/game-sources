using AnatomyJam.Character;
using AnatomyJam.Map;
using AnatomyJam.Player;
using System.Collections;
using UnityEngine;

namespace AnatomyJam.Manager
{
    public class GameManager : MonoBehaviour
    {
        [SerializeField]
        private PartyManager _party;

        [SerializeField]
        private MapScroller _scroller;

        [SerializeField]
        private UIDisplay _displayEnemy;

        [SerializeField]
        private SO.CharacterInfo[] _enemies;

        private CharacterBehavior _currentEnemy;
        private ProgressManager _progress;

        private bool _isFighting;

        private void Start()
        {
            _progress = GetComponent<ProgressManager>();
            MapScroller.S.ResetAll(_progress.CurrentZone);
            StartCoroutine(BeginRun());
        }

        private IEnumerator BeginRun()
        {
            _isFighting = false;

            // Update display and enable scrolling to make so that characters are moving

            _scroller.IsScrolling = true;
            _party.SetRunningState(true);
            _displayEnemy.Toggle(false);
            yield return new WaitForSeconds(3f);
            _scroller.IsScrolling = false;
            _party.SetRunningState(false);
            _displayEnemy.Toggle(true);

            // Movement done, we set the current enemy
            _currentEnemy = new(_displayEnemy, _progress.GetCurrentEnnemy());

            // Reset state for everyone
            _party.ReadyForFight();
            _currentEnemy.ReadyForFight();

            _isFighting = true;
        }

        private void Update()
        {
            if (_isFighting)
            {
                _party.UpdateTimers(_currentEnemy, Time.deltaTime);
                if (_currentEnemy.IsAlive)
                {
                    _currentEnemy.PassTime(Time.deltaTime, 1.5f);
                    if (_currentEnemy.CanAttack)
                    {
                        _currentEnemy.Attack(_party.GetRandomCharacter());

                        // Is hero party still alive?
                        if (!_party.IsPartyAlive)
                        {
                            _isFighting = false;
                            PlayerController.S.CanMove = false;
                            RetreatManager.S.DisplayRetreat(
                                () =>
                                {
                                    _progress.InitCurrentZone(); // Reset progression
                                    _displayEnemy.Toggle(false);
                                    _party.Rearm();
                                    _party.Revive();
                                    MapScroller.S.ResetAll(_progress.CurrentZone);
                                },
                                () =>
                                {
                                    PlayerController.S.CanMove = true;
                                    StartCoroutine(BeginRun());
                                });
                        }
                    }
                }
                else
                {
                    // Enemy was killed, let's fight the next one
                    _isFighting = false;
                    _progress.WinFight(() =>
                    {
                        StartCoroutine(BeginRun());
                    });
                }
            }
        }
    }
}
using LudumDare57.Manager;
using LudumDare57.Prop;
using LudumDare57.SO;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.UI;

namespace LudumDare57.Player
{
    public class Drill : MonoBehaviour
    {
        [SerializeField]
        private GameObject _drill;
        private SpriteRenderer _drillSr;

        [SerializeField]
        private SpriteRenderer _effectSr;

        [SerializeField]
        private TriggerDetector _drillTrigger;
        private CircleCollider2D _triggerColl;

        [SerializeField]
        private GameObject _breakEffect;

        [SerializeField]
        private Sprite[] _upgradedSprites;
        private int _upgradeIndex;

        [SerializeField]
        private Sprite[] _upgradedDrillEffect;
        private int _effectIndex;

        private PlayerController _controller;
        private PlayerInfo _info;

        private Vector2? _drillingDir;
        private Color _drillBaseColor;
        private float _drillTimer;
        private bool _canDrill = true;

        private float _drillCooldownRef;

        public bool IsDrilling => _drillingDir != null;
        public Vector2 DrilligDir => _drillingDir.Value;

        private readonly List<IDestructible> _targetedBlocks = new();

        public float DrillSpeedRef { private set; get; }
        private float _drillDurationRef;
        

        private void Awake()
        {
            _controller = GetComponent<PlayerController>();
            _info = _controller.Info;

            _drillCooldownRef = _info.DrillingCooldown;

            _drillSr = _drill.GetComponent<SpriteRenderer>();
            _drillBaseColor = _drillSr.color;

            DrillSpeedRef = _info.DrillingSpeed;
            _drillDurationRef = _info.DrillDuration;

            _drillTrigger.OnTriggerEnterEvt.AddListener((c) =>
            {
                var id = c.gameObject.GetInstanceID();
                if (c.gameObject.TryGetComponent<IDestructible>(out var d) && !_targetedBlocks.Any(tb => tb.GameObject.GetInstanceID() == id))
                {
                    _targetedBlocks.Add(d);
                    d.ToggleHighlight(true);
                }
            });
            _drillTrigger.OnTriggerExitEvt.AddListener((c) =>
            {
                if (c.gameObject.TryGetComponent<IDestructible>(out var d))
                {
                    d.ToggleHighlight(false);
                    var id = c.gameObject.GetInstanceID();
                    _targetedBlocks.RemoveAll(bl => bl.GameObject.GetInstanceID() == id);
                }
            });
            _triggerColl = _drillTrigger.GetComponent<CircleCollider2D>();
        }

        public void UpgradeDrillSize()
        {
            _triggerColl.radius += 1f;
            _drillSr.transform.localScale = new Vector3(_drillSr.transform.localScale.x + .2f, _drillSr.transform.localScale.y, _drillSr.transform.localScale.z);
        }
        public void UpgradeDrillCooldown()
        {
            _drillCooldownRef /= 2f;
            _drillSr.sprite = _upgradedSprites[_upgradeIndex];
            _upgradeIndex++;
        }

        public void UpgradeDrillSpeed()
        {
            DrillSpeedRef *= 2f;
            _drillDurationRef /= 1.5f;
            _effectSr.sprite = _upgradedDrillEffect[_effectIndex];
            _effectIndex++;
        }

        private void Update()
        {
            // Update drill timer
            if (!_canDrill)
            {
                _drillTimer -= Time.deltaTime;

                // Update drill color depending of how long we have been drilling
                if (_drillingDir != null) _drillSr.color = Color.Lerp(_drillBaseColor, Color.red, 1f - (_drillTimer / _drillDurationRef));
                else _drillSr.color = Color.Lerp(Color.red, _drillBaseColor, 1f - (_drillTimer / _drillCooldownRef));

                if (_drillTimer <= 0f)
                {
                    if (_drillingDir != null) // End of drill, start cooldown
                    {
                        _drillingDir = null;
                        _drillTimer = _drillCooldownRef;
                    }
                    else // End of cooldown, we can use the drill again
                    {
                        _canDrill = true;
                    }
                }
            }

            // Update drill object to follow mouse
            if (_drillingDir == null) // Can't change direction while drilling
            {
                var worldMouse = PlayerManager.Instance.Camera.ScreenToWorldPoint(Mouse.current.position.ReadValue());
                var dir = ((Vector2)(worldMouse - transform.position)).normalized;
                _drill.transform.up = dir;
                _drill.transform.position = transform.position + _drill.transform.up;
            }

            // Update drill to destroy blocks in range
            if (_drillingDir != null)
            {
                bool shouldStop = false;

                int amountGained = 0;
                for (int i = _targetedBlocks.Count - 1; i >= 0; i--)
                {
                    var bl = _targetedBlocks[i];
                    if (!bl.CanDestroy)
                    {
                        shouldStop = true;
                        bl.Stun(transform);
                        continue;
                    }
                    
                    amountGained += bl.MoneyGained;
                    Destroy(Instantiate(_breakEffect, bl.GameObject.transform.position, Quaternion.identity), .2f);
                    EnemyManager.Instance.Unregister(bl.GameObject);
                    bl.OnDestroy();
                    Destroy(bl.GameObject);
                }
                PlayerManager.Instance.GainMoney(amountGained);
                _targetedBlocks.RemoveAll(x => x.CanDestroy);

                if (shouldStop)
                {
                    AudioManager.Instance.PlayStun();
                    ResetDrill();
                }
            }
        }

        public void ResetDrill()
        {
            _drillTimer = 0f;
            _canDrill = true;
            _drillSr.color = _drillBaseColor;
            _drillingDir = null;
        }

        public void OnDrill(InputAction.CallbackContext value)
        {
            if (value.phase == InputActionPhase.Started && _canDrill)
            {
                // Clicking on some UI button shouldn't activate the drill
                PointerEventData pointerEventData = new(EventSystem.current)
                {
                    position = Mouse.current.position.ReadValue()
                };
                List<RaycastResult> raycastResultsList = new List<RaycastResult>();
                EventSystem.current.RaycastAll(pointerEventData, raycastResultsList);
                for (int i = 0; i < raycastResultsList.Count; i++)
                {
                    if (raycastResultsList[i].gameObject.TryGetComponent<Button>(out var _))
                    {
                        return;
                    }
                }

                var worldMouse = PlayerManager.Instance.Camera.ScreenToWorldPoint(Mouse.current.position.ReadValue());
                _drillingDir = ((Vector2)(worldMouse - transform.position)).normalized;

                _drillTimer = _drillDurationRef;
                _canDrill = false;

                AudioManager.Instance.PlayDrill();

                _controller.CancelRecall();
            }
        }
    }
}
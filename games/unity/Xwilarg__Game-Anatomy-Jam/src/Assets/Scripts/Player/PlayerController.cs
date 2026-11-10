using AnatomyJam.Material;
using AnatomyJam.SceneObjects;
using AnatomyJam.SceneObjects.Station;
using AnatomyJam.SO;
using TMPro;
using UnityEngine;
using UnityEngine.InputSystem;

namespace AnatomyJam.Player
{
    public class PlayerController : MonoBehaviour
    {
        public static PlayerController S;

        private void Awake()
        {
            S = this;
        }

        [SerializeField]
        private Transform _handsContainer;

        [SerializeField]
        private GameObject _pressE;

        [SerializeField]
        private PlayerInfo _info;

        private Rigidbody _rb;
        private Vector2 _mov;

        private Vector3 _initPos;

        private Interactible _currentInteraction;
        private SceneObject _inHands;

        private bool _canMove = true;

        public bool CanMove
        {
            private get => _canMove;
            set
            {
                if (!value)
                {
                    _rb.velocity = Vector3.zero;
                }
                _canMove = value;
            }
        }

        private void Start()
        {
            _rb = GetComponent<Rigidbody>();
            _initPos = transform.position;
        }

        private void FixedUpdate()
        {
            if (!_canMove)
            {
                return;
            }

            _rb.velocity = new(_mov.x, _rb.velocity.y, _mov.y);
            if (_mov != Vector2.zero)
            {
                transform.rotation = Quaternion.LookRotation(new(_mov.x, 0f, _mov.y));
                transform.Rotate(0f, -90f, 0f);
            }
        }

        private void OnCollisionEnter(Collision collision)
        {
            // Player falled in lava, we reset his position
            if (collision.collider.CompareTag("Lava"))
            {
                transform.position = _initPos;
            }
        }

        public void ResetInteraction()
        {
            _currentInteraction = null;
            _pressE.SetActive(false);
        }

        public void AddObjectFromChest(ObjectInfo obj)
            => AddObjectInHands(obj, -1f, null);

        /// <summary>
        /// Object taken from chest
        /// </summary>
        public void AddObjectInHands(ObjectInfo obj, float value, string text)
        {
            if (_inHands != null)
            {
                return;
            }

            var go = Instantiate(obj.GameObject, _handsContainer);
            go.transform.localPosition = Vector3.zero;
            go.transform.localScale
                = new Vector3(
                    obj.GameObject.transform.localScale.x * (1f / transform.localScale.x),
                    obj.GameObject.transform.localScale.y * (1f / transform.localScale.y),
                    obj.GameObject.transform.localScale.z * (1f / transform.localScale.z)
                    );

            if (text != null)
            {
                go.GetComponent<Armor>().Value = value;
                go.GetComponentInChildren<TMP_Text>().text = text;
            }

            _inHands = go.GetComponent<SceneObject>();
            _inHands.Init(obj, go);

            foreach (var coll in go.GetComponentsInChildren<Collider>())
            {
                coll.enabled = false;
            }
            var rb = go.GetComponent<Rigidbody>();
            if (rb != null)
            {
                rb.isKinematic = true;
            }
        }

        public void AddObjectToStation(AStation station)
        {
            if (_inHands != null)
            {
                ResetInteraction();

                station.Deposit(this, _inHands);
                _inHands.DestroyObject();
                _inHands = null;
            }
        }

        public void RemoveItemInHands()
        {
            _inHands.DestroyObject();
            _inHands = null;
        }

        public void OnMovement(InputAction.CallbackContext value)
        {
            _mov = value.ReadValue<Vector2>().normalized * _info.BaseSpeed;
        }

        public void OnInterract(InputAction.CallbackContext value)
        {
            if (value.phase == InputActionPhase.Started)
            {
                if (_currentInteraction != null)
                {
                    _currentInteraction.Invoke();
                }
            }
        }

        private void OnTriggerEnter(Collider other)
        {
            var otherC = other.GetComponent<Interactible>();
            if (otherC != null && ((otherC.CompareTag("GarbageCan") && _inHands != null) || (!otherC.CompareTag("GarbageCan") && otherC.IsValid(_inHands))))
            {
                _currentInteraction = otherC;
                _pressE.SetActive(true);
            }
        }

        private void OnTriggerExit(Collider other)
        {
            var otherC = other.GetComponent<Interactible>();
            if (_currentInteraction == otherC)
            {
                _currentInteraction = null;
                _pressE.SetActive(false);
            }
        }
    }
}

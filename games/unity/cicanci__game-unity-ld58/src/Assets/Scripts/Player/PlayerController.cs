using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent (typeof(BaseStats), typeof(Rigidbody))]
public class PlayerController : MonoBehaviour
{
    private BaseStats _stats;
    private InputControls _controls;
    private Rigidbody _rigidbody;
    private Vector2 _input;
    private Coroutine _damageCoroutine;
    private float _fullHealth;

    public static PlayerController Instance { get; private set; }

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }

        _controls = new InputControls();
        _rigidbody = GetComponent<Rigidbody>();
        _stats = GetComponent<BaseStats>();

        _fullHealth = _stats.Health;
        MessageQueue.Instance.SendMessage(new HealthUpdateMessage() { Amount = _fullHealth });
    }

    private void OnEnable()
    {
        _controls.Player.Enable();
        _controls.Player.Move.performed += context => _input = context.ReadValue<Vector2>();
        _controls.Player.Move.canceled += _ => _input = Vector2.zero;
    }

    private void OnDisable()
    {
        _controls.Player.Disable();
    }

    private void FixedUpdate()
    {
        Vector3 move = new Vector3(_input.x, 0, _input.y);
        _rigidbody.MovePosition(_rigidbody.position + move * _stats.MovementSpeed * Time.fixedDeltaTime);
    }

    private void OnCollisionEnter(Collision collision)
    {
        if (collision.collider.CompareTag("Enemy"))
        {
            Debug.Log($"PlayerController.OnCollisionEnter: {collision.collider.name}");
            _damageCoroutine = StartCoroutine(_stats.DamageOverTime(collision.gameObject));
        }

        if (collision.collider.CompareTag("Card"))
        {
            Debug.Log($"PlayerController.OnCollisionEnter: {collision.collider.name}");
            collision.gameObject.GetComponent<CardController>().PickUpCard();

            // Restores player health when picking up any card
            _stats.Health = _fullHealth;
            MessageQueue.Instance.SendMessage(new HealthUpdateMessage() { Amount = _fullHealth });
        }
    }

    private void OnCollisionExit(Collision collision)
    {
        if (collision.collider.CompareTag("Enemy"))
        {
            Debug.Log($"PlayerController.OnCollisionExit: {collision.collider.name}");
            StopDamageOverTime();
        }
    }

    private void StopDamageOverTime()
    {
        if (_damageCoroutine != null)
        {
            StopCoroutine(_damageCoroutine);
            _damageCoroutine = null;
        }
    }
}

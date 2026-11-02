using UnityEngine;
using UnityEngine.InputSystem;

public class Paul : MonoBehaviour
{
    public float speed = 5f;
    Rigidbody2D rb;
    Vector2 input;

    void Awake() => rb = GetComponent<Rigidbody2D>();

    void Update()
    {
        input = Vector2.zero;
        if (Keyboard.current == null) return;

        if (Keyboard.current.aKey.isPressed) input.x--;
        if (Keyboard.current.dKey.isPressed) input.x++;
        if (Keyboard.current.sKey.isPressed) input.y--;
        if (Keyboard.current.wKey.isPressed) input.y++;

        input = input.normalized;
    }

    void FixedUpdate() => rb.linearVelocity = input * speed;
}

using UnityEngine;

public class PlayerBall : MonoBehaviour
{
    public float moveSpeed = 5.5f;
    public float jumpForce = 11.5f;

    public Transform groundCheck;
    public float groundCheckRadius = 0.15f;
    public LayerMask groundLayer;

    private Rigidbody2D rb;
    private float horizontal;
    private bool jumpPressed;
    private bool isGrounded;

    // Estado de los controles táctiles
    private bool mobileLeftPressed;
    private bool mobileRightPressed;
    private bool mobileJumpRequested;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
    }

    void Update()
    {
        // -------------------------------
        // 1. MOVIMIENTO HORIZONTAL
        // -------------------------------

        horizontal = 0f;

        // Controles de ordenador: A y D
        if (Input.GetKey(KeyCode.A))
        {
            horizontal -= 1f;
        }

        if (Input.GetKey(KeyCode.D))
        {
            horizontal += 1f;
        }

        // Controles táctiles de móvil
        if (mobileLeftPressed)
        {
            horizontal -= 1f;
        }

        if (mobileRightPressed)
        {
            horizontal += 1f;
        }

        // Limitar el valor del movimiento
        horizontal = Mathf.Clamp(horizontal, -1f, 1f);

        // -------------------------------
        // 2. SALTO
        // -------------------------------

        // Salto mediante la barra espaciadora
        if (Input.GetKeyDown(KeyCode.Space))
        {
            jumpPressed = true;
        }

        // -------------------------------
        // 3. DETECCIÓN DEL SUELO
        // -------------------------------

        if (groundCheck != null)
        {
            isGrounded = Physics2D.OverlapCircle(
                groundCheck.position,
                groundCheckRadius,
                groundLayer
            ) != null;
        }
        else
        {
            isGrounded = false;
        }
    }

    void FixedUpdate()
    {
        if (rb == null)
        {
            return;
        }

        // Aplicar movimiento horizontal
        rb.linearVelocity = new Vector2(
            horizontal * moveSpeed,
            rb.linearVelocity.y
        );

        // Saltar desde el teclado o desde el móvil
        if ((jumpPressed || mobileJumpRequested) && isGrounded)
        {
            rb.linearVelocity = new Vector2(
                rb.linearVelocity.x,
                jumpForce
            );
        }

        // Consumir las solicitudes de salto
        jumpPressed = false;
        mobileJumpRequested = false;
    }

    // -------------------------------
    // 4. CONTROLES TÁCTILES
    // -------------------------------

    // Botón izquierdo: pulsado o soltado
    public void SetMobileLeft(bool pressed)
    {
        mobileLeftPressed = pressed;
    }

    // Botón derecho: pulsado o soltado
    public void SetMobileRight(bool pressed)
    {
        mobileRightPressed = pressed;
    }

    // Solicitar un salto desde el botón táctil
    public void RequestMobileJump()
    {
        mobileJumpRequested = true;
    }
}
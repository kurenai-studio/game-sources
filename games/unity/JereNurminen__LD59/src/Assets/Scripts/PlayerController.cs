using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerController : MonoBehaviour
{
    [SerializeField]
    private float acceleration = 10f; // m/s²

    [SerializeField]
    private float topSpeed = 10f;

    [SerializeField]
    private float reverseTopSpeed = 4f;

    [SerializeField]
    private float brakePower = 20f;

    [SerializeField]
    private float turnSpeed = 90f; // degrees/sec

    [SerializeField]
    private Sprite[] directionSprites = new Sprite[16]; // 16 directions, top-down

    [SerializeField]
    private Vector2 beamPivotOffset = Vector2.zero;

    public Vector2 BeamPosition => (Vector2)transform.position + beamPivotOffset;

    // directionSprites index mapping (clockwise from North):
    //  0=N  1=NNE  2=NE  3=ENE  4=E  5=ESE  6=SE  7=SSE
    //  8=S  9=SSW 10=SW 11=WSW 12=W 13=WNW 14=NW 15=NNW

    // Current facing direction in degrees, clockwise from North
    private float currentAngle = 0f;
    private float currentSpeed = 0f;

    public float CurrentAngle => currentAngle;
    public Vector2 Velocity => rb.linearVelocity;

    private InputAction steerAction;
    private InputAction throttleAction;
    private InputAction brakeAction;
    private InputAction phoneAction;
    private SpriteRenderer spriteRenderer;
    private Rigidbody2D rb;
    private Collider2D col;
    public bool isControlEnabled = true;

    private void Awake()
    {
        spriteRenderer = GetComponent<SpriteRenderer>();
        rb = GetComponent<Rigidbody2D>();
        col = GetComponent<Collider2D>();

        steerAction = InputSystem.actions.FindAction("Steer");
        throttleAction = InputSystem.actions.FindAction("Throttle");
        brakeAction = InputSystem.actions.FindAction("Brake");
        phoneAction = InputSystem.actions.FindAction("Phone");
    }

    private void OnEnable()
    {
        steerAction.Enable();
        throttleAction.Enable();
        brakeAction.Enable();
        phoneAction.Enable();
    }

    private void OnDisable()
    {
        steerAction.Disable();
        throttleAction.Disable();
        brakeAction.Disable();
        phoneAction.Disable();
    }

    public void Stop(bool? immediate = false)
    {
        if (immediate.HasValue && immediate.Value)
            currentSpeed = 0f;

        isControlEnabled = false;
    }

    // Update is called once per frame
    void Update()
    {
        float steerInput = isControlEnabled ? steerAction.ReadValue<Vector2>().x : 0f;
        float throttleInput = isControlEnabled ? throttleAction.ReadValue<float>() : 0f;
        bool brakeHeld = !isControlEnabled || brakeAction.IsPressed();
        bool phoneActive = phoneAction.IsPressed();

        // Steering scaled by speed fraction; inverted when reversing
        float speedFraction = Mathf.Clamp01(Mathf.Abs(currentSpeed) / topSpeed);
        float steerDir = currentSpeed < 0f ? -1f : 1f;
        if (!phoneActive && steerInput != 0f)
            currentAngle =
                (
                    currentAngle
                    + steerInput * steerDir * turnSpeed * speedFraction * Time.deltaTime
                    + 360f
                ) % 360f;

        // Acceleration / braking / reverse
        if (!phoneActive && throttleInput > 0f)
            currentSpeed = Mathf.MoveTowards(
                currentSpeed,
                topSpeed,
                acceleration * throttleInput * Time.deltaTime
            );
        else if (!phoneActive && brakeHeld)
        {
            if (currentSpeed > 0f || !isControlEnabled)
                currentSpeed = Mathf.MoveTowards(currentSpeed, 0f, brakePower * Time.deltaTime);
            else
                currentSpeed = Mathf.MoveTowards(
                    currentSpeed,
                    -reverseTopSpeed,
                    acceleration * Time.deltaTime
                );
        }
        else
            currentSpeed = Mathf.MoveTowards(currentSpeed, 0f, brakePower * Time.deltaTime);

        // Move in the facing direction (negative speed = reverse)
        Vector2 facingDirection = AngleToDirection(currentAngle);
        rb.linearVelocity = facingDirection * currentSpeed;

        spriteRenderer.sprite = GetSpriteForDirection(facingDirection);
        float sortY = col.bounds.center.y;
        spriteRenderer.sortingOrder = Mathf.RoundToInt(-sortY);
    }

    // Converts a clockwise-from-North angle (degrees) to a Vector2
    private Vector2 AngleToDirection(float angleCWFromNorth)
    {
        float rad = (90f - angleCWFromNorth) * Mathf.Deg2Rad;
        return new Vector2(Mathf.Cos(rad), Mathf.Sin(rad));
    }

    private Sprite GetSpriteForDirection(Vector2 direction)
    {
        if (direction == Vector2.zero)
            return directionSprites[0];

        float angleCCWFromEast = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg;
        float angleCWFromNorth = (90f - angleCCWFromEast + 360f) % 360f;
        int index = Mathf.RoundToInt(angleCWFromNorth / 22.5f) % 16;
        return directionSprites[index];
    }
}

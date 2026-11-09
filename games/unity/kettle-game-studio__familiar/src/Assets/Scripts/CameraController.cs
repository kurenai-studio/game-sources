
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public Animator animator;
    public Player player;
    public float playerViewK = 0.1f;
    public float playerViewSpeed = 0.1f;
    public SpriteRenderer blackScreen;
    public float blackoutOnTime = 1;
    public float blackoutOffTime = 1;
    float blackoutTimer;
    bool blackout = false;

    Vector3 basePosition;

    void Start()
    {
        basePosition = transform.position;
    }

    void FixedUpdate()
    {
        if (player == null)
            return;
        float targetShift = (player.transform.position.x - basePosition.x) * playerViewK;
        float currentShift = transform.position.x - basePosition.x;
        float x = Mathf.Lerp(currentShift, targetShift, playerViewSpeed);
        transform.position = basePosition + Vector3.right * x;
    }

    void Update()
    {
        float blackoutValue = blackout ? 1 - blackoutTimer / blackoutOffTime : blackoutTimer / blackoutOnTime;
        blackoutValue = Mathf.Clamp(blackoutValue, 0, 1);
        Color color = blackScreen.color;
        blackScreen.color = new Color(color.r, color.g, color.b, 1 - blackoutValue);
        blackoutTimer += Time.deltaTime;
    }

    public void BlackoutOn()
    {
        blackout = true;
        blackoutTimer = 0;
    }

    public void BlackoutOff()
    {
        blackout = false;
        blackoutTimer = 0;
    }

    public void ShakeDown() => animator.SetTrigger("ShakeDown");
    public void ShakeUp() => animator.SetTrigger("ShakeUp");
}

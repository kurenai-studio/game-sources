
using UnityEngine;
using UnityEngine.EventSystems;

public class MobileControlButton : MonoBehaviour,
    IPointerDownHandler,
    IPointerUpHandler,
    IPointerExitHandler
{
    public enum ControlType
    {
        Left,
        Right,
        Jump
    }

    [SerializeField] private PlayerBall player;
    [SerializeField] private ControlType controlType;

    public void OnPointerDown(PointerEventData eventData)
    {
        if (player == null)
            return;

        switch (controlType)
        {
            case ControlType.Left:
                player.SetMobileLeft(true);
                break;

            case ControlType.Right:
                player.SetMobileRight(true);
                break;

            case ControlType.Jump:
                player.RequestMobileJump();
                break;
        }
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        ReleaseMovement();
    }

    public void OnPointerExit(PointerEventData eventData)
    {
        ReleaseMovement();
    }

    private void ReleaseMovement()
    {
        if (player == null)
            return;

        if (controlType == ControlType.Left)
            player.SetMobileLeft(false);

        if (controlType == ControlType.Right)
            player.SetMobileRight(false);
    }

    private void OnDisable()
    {
        ReleaseMovement();
    }
}

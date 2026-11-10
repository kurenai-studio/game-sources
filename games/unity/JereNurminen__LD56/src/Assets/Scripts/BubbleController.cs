using UnityEngine;

public class BubbleController : MonoBehaviour
{
    private PlayerController parentPlayerController;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        parentPlayerController = GetComponentInParent<PlayerController>();
    }

    // Update is called once per frame
    void Update() { }

    public void OnCommandAnimationComplete()
    {
        parentPlayerController.OnCommandAnimationComplete();
    }
}

using UnityEngine;
using TMPro;

public class StartPromptController : MonoBehaviour
{
    private const float BlinkSpeed = 5f;
    private const float MinAlpha = 0.5f;
    private const float MaxAlpha = 1f;

    [SerializeField] private TMP_Text promptText;

    private void Update()
    {
        float t = (Mathf.Sin(Time.time * BlinkSpeed) + 1f) * 0.5f;
        Color color = promptText.color;
        color.a = Mathf.Lerp(MinAlpha, MaxAlpha, t);
        promptText.color = color;
    }
}
    
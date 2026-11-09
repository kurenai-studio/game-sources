using UnityEngine;
using UnityEngine.UI;

public class ScreenFader : MonoBehaviour
{
    [SerializeField]
    protected float solidAlpha = 1f; // 1f is for fully opaque.

    [SerializeField]
    protected float clearAlpha = 0f; // 0f is for fully transparent.

    [SerializeField]
    private float fadeOnDuration = 2f;
    public float FadeOnDuration
    {
        get
        {
            return this.fadeOnDuration;
        }
    }

    [SerializeField]
    private float fadeOffDuration = 2f;
    public float FadeOffDuration
    {
        get
        {
            return this.fadeOffDuration;
        }
    }

    [SerializeField]
    private MaskableGraphic[] graphicsToFade;

    protected void SetAlpha(float alpha)
    {
        foreach (MaskableGraphic graphic in this.graphicsToFade)
        {
            if (graphic != null)
            {
                graphic.canvasRenderer.SetAlpha(alpha);
            }
        }
    }

    private void Fade(float targetAlpha, float duration)
    {
        foreach (MaskableGraphic graphic in this.graphicsToFade)
        {
            if (graphic != null)
            {
                graphic.CrossFadeAlpha(targetAlpha, duration, true);
            }
        }
    }

    public void FadeOn()
    {
        SetAlpha(this.clearAlpha);
        Fade(this.solidAlpha, this.fadeOnDuration);
    }

    public void FadeOff()
    {
        SetAlpha(this.solidAlpha);
        Fade(this.clearAlpha, this.fadeOffDuration);
    }
}

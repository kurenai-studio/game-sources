using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

[RequireComponent(typeof(CanvasRenderer))]
public class FadingUI : MonoBehaviour
{
    public float stay = 2f;
    public float fade = 1f;

    CanvasRenderer cr;

    private void Start()
    {
        cr = GetComponent<CanvasRenderer>();
        StartCoroutine(Fade());
    }

    IEnumerator Fade()
    {
        cr.SetAlpha(1f);
        yield return new WaitForSeconds(stay);
        float time = Time.unscaledDeltaTime;
        while (time < fade)
        {
            cr.SetAlpha(1f - time / fade);
            yield return null;
            time += Time.unscaledDeltaTime;
        }
        gameObject.SetActive(false);
    }
}

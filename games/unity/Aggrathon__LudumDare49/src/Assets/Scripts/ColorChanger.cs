using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ColorChanger : MonoBehaviour
{

    public float delay = 0f;
    public float time = 6f;
    public ColorPalette palette;

    SpriteRenderer[] renderers;

    void OnEnable()
    {
        renderers = GetComponentsInChildren<SpriteRenderer>();
        StartCoroutine(Repeater());
    }

    IEnumerator Repeater()
    {
        WaitForSeconds wfs;
        if (delay > 0)
        {
            wfs = new WaitForSeconds(delay);
            ChangeColors();
            yield return wfs;
        }
        wfs = new WaitForSeconds(time);
        while (true)
        {
            ChangeColors();
            yield return wfs;
        }
    }

    void ChangeColors()
    {
        Color c = palette.Sample();
        foreach (var r in renderers)
        {
            r.color = c;
        }
    }
}

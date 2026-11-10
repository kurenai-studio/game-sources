using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[CreateAssetMenu(fileName = "ColorPalette", menuName = "ColorPalette", order = 1)]
public class ColorPalette : ScriptableObject
{
    public List<Color> colors;

    public Color Sample()
    {
        return colors.Sample();
    }

#if UNITY_EDITOR
    [ContextMenu("Paste HTML colors")]
    public void PasteColors()
    {
        foreach (var s in UnityEditor.EditorGUIUtility.systemCopyBuffer.Split(' '))
        {
            if (ColorUtility.TryParseHtmlString(s, out Color color))
            {
                colors.Add(color);
            }
        }
    }

    [ContextMenu("Fill Sample colors")]
    public void FillColors()
    {
        colors.Clear();
        for (float i = 0; i < 10; i++)
        {
            colors.Add(Color.HSVToRGB(i / 10, 0.4f, 1.0f));
        }
        for (float i = 0.66f; i < 10; i++)
        {
            colors.Add(Color.HSVToRGB(i / 10, 0.3f, 0.95f));
        }
        for (float i = 0.33f; i < 10; i++)
        {
            colors.Add(Color.HSVToRGB(i / 10, 0.5f, 0.9f));
        }
    }
#endif
}

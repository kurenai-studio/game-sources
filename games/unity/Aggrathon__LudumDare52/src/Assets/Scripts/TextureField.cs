using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Field))]
public class TextureField : MonoBehaviour
{
    public Texture2D texture;
    public Color soilColor;

    [Range(0, 1)] public float treshold = 0.1f;

    Field field;

    [ContextMenu("Refresh Gizmos")]
    void Start()
    {
        field = GetComponent<Field>();
        var renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            var bounds = renderer.bounds;
            field.width = Mathf.Abs(bounds.center.x - transform.position.x) * 2 + bounds.size.x;
            field.length = Mathf.Abs(bounds.center.z - transform.position.z) * 2 + bounds.size.z;
        }
        field.SetupGrid(IsSoil);
    }

    bool IsSoil(int i, int j)
    {
        i = Mathf.RoundToInt((1f - (float)i / (float)(field.columns - 1)) * (float)(texture.width - 1));
        j = Mathf.RoundToInt((1f - (float)j / (float)(field.rows - 1)) * (float)(texture.height - 1));
        return Utils.SimilarColor(texture.GetPixel(i, j), soilColor, treshold);
    }

}

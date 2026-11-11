using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class SetTexture : MonoBehaviour
{
    public Texture texture;
    public int materialIndex = 0;
    Renderer targetRenderer;
    Texture lastTexture = null;

    void Start()
    {
        targetRenderer = GetComponent<Renderer>();
    }

    void Update()
    {
        if (texture != lastTexture)
        {
            targetRenderer.materials[materialIndex].mainTexture = texture;
            lastTexture = texture;
        }
    }
}

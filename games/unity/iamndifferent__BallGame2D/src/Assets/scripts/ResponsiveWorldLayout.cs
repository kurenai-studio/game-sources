
using UnityEngine;

public class ResponsiveWorldLayout : MonoBehaviour
{
    [Header("Objetos del escenario")]
    [SerializeField] private Transform[] worldObjects;

    [Header("Ajustes de pantalla vertical")]
    [SerializeField, Range(0.1f, 1f)]
    private float portraitHorizontalScale = 0.35f;

    private Vector3[] originalPositions;
    private int previousWidth = -1;
    private int previousHeight = -1;

    private void Awake()
    {
        if (worldObjects == null)
            return;

        originalPositions = new Vector3[worldObjects.Length];

        for (int i = 0; i < worldObjects.Length; i++)
        {
            if (worldObjects[i] != null)
                originalPositions[i] = worldObjects[i].position;
        }

        ApplyLayout();
    }

    private void Update()
    {
        if (Screen.width != previousWidth ||
            Screen.height != previousHeight)
        {
            ApplyLayout();
        }
    }

    private void ApplyLayout()
    {
        previousWidth = Screen.width;
        previousHeight = Screen.height;

        if (worldObjects == null || originalPositions == null)
            return;

        bool isPortrait = Screen.height > Screen.width;

        float horizontalScale = isPortrait
            ? portraitHorizontalScale
            : 1f;

        for (int i = 0; i < worldObjects.Length; i++)
        {
            if (worldObjects[i] == null)
                continue;

            Vector3 position = originalPositions[i];

            position.x = originalPositions[i].x * horizontalScale;

            worldObjects[i].position = position;
        }
    }
}

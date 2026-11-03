
using UnityEngine;
using TMPro;

public class HeightCounter : MonoBehaviour
{
    public Transform player;
    public TMP_Text heightText;
    public TMP_Text finalHeightText;

    private float startY;
    private float highestY;
    private bool gameEnded = false;

    void Start()
    {
        startY = player.position.y;
        highestY = startY;

        UpdateHeightText();
    }

    void Update()
    {
        if (gameEnded)
        {
            return;
        }

        if (player.position.y > highestY)
        {
            highestY = player.position.y;
        }

        UpdateHeightText();
    }

    void UpdateHeightText()
    {
        int height = Mathf.Max(
            0,
            Mathf.FloorToInt(highestY - startY)
        );

        heightText.text = "ALTURA: " + height + " m";
    }

    public void ShowFinalHeight()
    {
        gameEnded = true;

        int height = Mathf.Max(
            0,
            Mathf.FloorToInt(highestY - startY)
        );

        finalHeightText.text =
            "DISTANCIA ALCANZADA: " + height + " m";
    }
}

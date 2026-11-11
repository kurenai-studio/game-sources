using UnityEngine;
using TMPro;

public class HUDManager : MonoBehaviour
{
    [SerializeField]
    private TextMeshProUGUI scoreText; // Reference to the TMP Text component

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start() { }

    // Update is called once per frame
    void Update() { }

    // Method to update the score display
    public void UpdateScore(int score)
    {
        scoreText.text = $"<mspace=0.5em>{score.ToString().PadLeft(12, '0')}</mspace>";
    }
}

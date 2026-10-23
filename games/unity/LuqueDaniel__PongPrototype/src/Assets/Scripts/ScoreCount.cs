using UnityEngine;
using UnityEngine.UI;

public class ScoreCount : MonoBehaviour
{
    int playerOnePoints;
    int playerTwoPoints;

    void OnCollisionEnter2D(Collision2D collision)
    {
        if (name == "Limit Left")
        {
            playerTwoPoints++;
            GameObject.Find("Player2Score").GetComponent<Text>().text = playerTwoPoints.ToString();
        }
        else
        {
            playerOnePoints++;
            GameObject.Find("Player1Score").GetComponent<Text>().text = playerOnePoints.ToString();
        }
        
        GameController.softGameReset();
    }
}

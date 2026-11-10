using System;
using UnityEngine;
using UnityEngine.UI;

public class Gamestate : MonoBehaviour
{
    int sheepCount = 0;

    [SerializeField] Text time;
    [SerializeField] Text sheepLeft;

    [SerializeField] Text gameOver;

    float timer = 0.0f;

    void Start()
    {
        sheepCount = FindObjectsOfType<SheepController>().Length;
        Debug.Log(sheepCount + " sheep found!");
    }

    void Update()
    {
        if(!IsGameOver())
        {
            sheepLeft.text = "Sheep left: " + sheepCount;

            timer += Time.deltaTime;
            int seconds = (int)timer;
            TimeSpan timeSpan = TimeSpan.FromSeconds(seconds);
            string timeText = string.Format("{0:D2}:{1:D2}:{2:D2}", timeSpan.Hours, timeSpan.Minutes, timeSpan.Seconds);

            time.text = "Time: " + timeText;
        } else
        {
            sheepLeft.text = "Sheep left: " + sheepCount;
            gameOver.enabled = true;
        }
    }

    public void OnSheepKilled()
    {
        sheepCount--;
    }

    public bool IsGameOver()
    {
        return sheepCount <= 0;
    }
}

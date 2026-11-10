using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

[RequireComponent(typeof(Collider2D))]
public class Objective : MonoBehaviour
{
    float startTime;
    int bestTime;
    string sceneName;
    int attempts;
    int penalty;
    List<Rigidbody2D> inTrigger;
    int currentTime;
    bool stable;

    public TextMeshProUGUI text;
    public GameObject victoryPopup;
    public TextMeshProUGUI victoryScore;
    public int penaltyMultiplier = 10;
    public AudioClip penaltySound;
    public AudioClip victorySound;


    private void OnEnable()
    {
        sceneName = LevelManager.GetSceneName();
        startTime = Time.time;
        bestTime = PlayerPrefs.GetInt("time_" + sceneName, 9999);
        string key = "num_" + sceneName;
        attempts = PlayerPrefs.GetInt(key, 0);
        PlayerPrefs.SetInt(key, attempts + 1);
        PlayerPrefs.Save();
        inTrigger = new List<Rigidbody2D>();
        penalty = 0;
        currentTime = -1;
        stable = false;
    }

    private void OnDisable()
    {
        if (Time.time - startTime < 10f)
        {
            PlayerPrefs.SetInt("num_" + sceneName, attempts);
            PlayerPrefs.Save();
        }
    }

    public void AddPenalty(Vector2 pos)
    {
        penalty++;
        currentTime = -1;
        Update();
        AudioManager.Play(penaltySound, pos, AudioManager.SoundType.Alert);
    }

    private void Update()
    {
        int time = Mathf.RoundToInt(Time.time - startTime);
        if (time != currentTime)
        {
            currentTime = time;
            text.text = string.Format("{0}\n\nTime: {1,6:d}\nPenalty: {2,3:d}\n\nAttempts: {3,2:d}\nBest: {4,6:d}", sceneName, time, penalty * penaltyMultiplier, attempts, bestTime);
        }
    }

    void OnFinish()
    {
        int time = Mathf.RoundToInt(Time.time - startTime);
        time += penalty * penaltyMultiplier;
        if (time < bestTime)
        {
            bestTime = time;
            attempts++;
            PlayerPrefs.SetInt("time_" + sceneName, time);
            PlayerPrefs.Save();
            victoryScore.text = string.Format("Final Time: {0}\nNew Record!", time);
        }
        else
        {
            victoryScore.text = string.Format("Final Time: {0}", time);
        }
        victoryPopup.SetActive(true);
        currentTime -= 1;
        Update();
        enabled = false;
        AudioManager.Play(victorySound);
    }


    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.attachedRigidbody)
            inTrigger.Add(other.attachedRigidbody);
    }

    private void OnTriggerExit2D(Collider2D other)
    {
        if (other.attachedRigidbody)
            inTrigger.Remove(other.attachedRigidbody);
    }

    private void FixedUpdate()
    {
        if (inTrigger.Count > 1)
        {
            int cnt = 0;
            foreach (var item in inTrigger)
            {
                if (!item.isKinematic && (item.IsSleeping() || (Vector2.SqrMagnitude(item.velocity) < 0.001f && item.angularVelocity < 0.1f)))
                {
                    cnt++;
                }
            }
            if (cnt > 1)
            {
                if (stable)
                    OnFinish();
                else
                    stable = true;
            }
            else
            {
                stable = false;
            }
        }
    }
}

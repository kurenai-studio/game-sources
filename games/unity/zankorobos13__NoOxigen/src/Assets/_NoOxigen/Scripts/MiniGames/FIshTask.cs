using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class FIshTask : MonoBehaviour
{
    public GameObject timer;
    public GameObject feed;
    void Start()
    {
        
    }

    void Update()
    {
        if (G.GetOvertimedBreakings().Contains(GetComponent<TaskChars>().breakingType))
        {
            OnFailed();
        }

        float time = 0f;
        if (G.breakings_timers.ContainsKey(GetComponent<TaskChars>().breakingType))
            time = (G.BREAKING_TIME - G.breakings_timers[GetComponent<TaskChars>().breakingType]);

        if (time < 0)
        {
            time = 0f;
            OnFailed();
        }

        timer.GetComponent<TextMeshProUGUI>().text = time.ToString("F1");
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Close();
        }

    }
    public void Close()
    {
        G.OnBreakingClosed();
        Destroy(gameObject);
    }

    private void Win()
    {
        G.breakings.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.breakings_timers.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.OnBreakingUpdated();
        G.OnSuccessed();
        Close();
    }

    public void OnFailed()
    {
        G.breakings.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.breakings_timers.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        Main2.BreakingsList.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.player_hp -= 40f;
        G.OnBreakingUpdated();
        G.OnFailed();
        Close();
    }

    public void Good()
    {
        StartCoroutine(WinWin());
    }

    private IEnumerator WinWin()
    {
        feed.GetComponent<Animator>().SetBool("Feed", true);
        yield return new WaitForSeconds(0.7f);
        Win();
    }
}

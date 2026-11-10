using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;

public class SlidersTask : MonoBehaviour
{
    public List<GameObject> sliders = new List<GameObject>(4);
    public GameObject timer;
    void Start()
    {
        G.AllRepStopped += OnFailed;
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

        if (CheckSliders())
            Win();
    }

    private bool CheckSliders()
    {
        return sliders[0].GetComponent<Scrollbar>().value == 1 && sliders[1].GetComponent<Scrollbar>().value == 0 && sliders[2].GetComponent<Scrollbar>().value == 0 && sliders[3].GetComponent<Scrollbar>().value == 1;
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

    private void OnFailed()
    {
        G.breakings.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.breakings_timers.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        Main2.BreakingsList.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.player_hp -= 20;
        G.OnBreakingUpdated();
        G.OnFailed();
        Close();
    }
}

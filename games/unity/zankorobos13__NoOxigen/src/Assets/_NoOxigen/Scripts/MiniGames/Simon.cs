using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class Simon : MonoBehaviour
{

    public enum Color
    {
        Yellow,
        Red,
        Green,
        Blue
    };
    public GameObject timer;
    public List<Color> goal_seq;
    public GameObject infoText;
    private int iter = 0;
    private bool isAbleToEnterSeq = false;

    void Start()
    {
        GenSeq(5);
        StartCoroutine(PlayGoalSeq());
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
    }

    public void Close()
    {
        G.OnBreakingClosed();
        Destroy(gameObject);
    }

    private void GenSeq(int len)
    {
        goal_seq.Clear();

        for (int i = 0; i < len; i++)
        {
            Color randColor = (Color)Random.Range(0, 4);
            goal_seq.Add(randColor);
        }
    }

    private IEnumerator PlayGoalSeq()
    {
        isAbleToEnterSeq = false;
        foreach (var color in goal_seq)
        {
            if (this == null || gameObject == null)
            {
                yield break;
            }
            Debug.Log(color.ToString());
            gameObject.transform.Find("Buttons").Find(color.ToString()).GetComponent<Animator>().SetBool("isNeedToBlink", true);
            yield return new WaitForEndOfFrame(); 
            gameObject.transform.Find("Buttons").Find(color.ToString()).GetComponent<Animator>().SetBool("isNeedToBlink", false);
            yield return new WaitForSeconds(0.7f);
        }
        isAbleToEnterSeq = true;
        iter = 0;
    }

    public void Reset()
    {
        if (!isAbleToEnterSeq)
            return;
        iter = 0;
        GenSeq(5);
        StartCoroutine(PlayGoalSeq());
    }

    public void OnYellowClick()
    {
        OnColorClick(Color.Yellow);
    }
    public void OnRedClick()
    {
        OnColorClick(Color.Red);
    }
    public void OnGreenClick()
    {
        OnColorClick(Color.Green);
    }
    public void OnBlueClick()
    {
        OnColorClick(Color.Blue);
    }

    private void OnColorClick(Color color)
    {
        if (!isAbleToEnterSeq)
            return;

        if (goal_seq[iter] == color)
            iter++;
        else
        {
            Reset();
            G.OnErrored();
            StartCoroutine(PrintErrorMSG());
        }
            

        if (iter == goal_seq.Count)
            Win();
    }

    private void Win()
    {
        G.breakings.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.breakings_timers.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.OnBreakingUpdated();
        G.OnSuccessed();
        Close();
    }

    private IEnumerator PrintErrorMSG()
    {
        infoText.GetComponent<TextMeshProUGUI>().text = "Wrong!";
        yield return new WaitForSeconds(1.5f);
        infoText.GetComponent<TextMeshProUGUI>().text = "";
    }

    private void OnFailed()
    {
        G.breakings.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.breakings_timers.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        Main2.BreakingsList.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.player_hp -= 10f;
        G.OnBreakingUpdated();
        G.OnFailed();
        Close();
    }
}

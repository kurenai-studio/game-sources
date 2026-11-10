using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class StatsScript : MonoBehaviour
{
    public GameObject hp_bar;
    public GameObject timer;

    private float recent_hp;
    void Start()
    {
        recent_hp = G.player_hp;
        float goal_x_scale = G.player_hp / 100;
        hp_bar.transform.Find("red").GetComponent<RectTransform>().localScale = new Vector3(goal_x_scale, 1f, 1f);
        hp_bar.transform.Find("white").GetComponent<RectTransform>().localScale = new Vector3(goal_x_scale, 1f, 1f);

    }

    // Update is called once per frame
    void Update()
    {
        timer.GetComponent<TextMeshProUGUI>().text = "Oxygen: " + (G.MAIN_TIME - G.main_timer).ToString("F1");

        

        if (G.player_hp != recent_hp)
        {
            float initial_x_scale = hp_bar.transform.Find("red").GetComponent<RectTransform>().localScale.x;
            float goal_x_scale = G.player_hp / 100;
            hp_bar.transform.Find("red").GetComponent<RectTransform>().localScale = new Vector3(goal_x_scale, 1f, 1f);
            StartCoroutine(WhiteHPTrail(initial_x_scale, goal_x_scale, 0.5f));
            recent_hp = G.player_hp;
        }
    }

    private IEnumerator WhiteHPTrail(float initial_x_scale, float goal_x_scale, float duration)
    {
        float elapsed = 0f;

        while (elapsed < duration)
        {
            float x_scale = Mathf.Lerp(initial_x_scale, goal_x_scale, elapsed / duration);
            hp_bar.transform.Find("white").GetComponent<RectTransform>().localScale = new Vector3(x_scale, 1f, 1f);
            elapsed += Time.deltaTime;
            yield return null;
        }
        hp_bar.transform.Find("white").GetComponent<RectTransform>().localScale = new Vector3(goal_x_scale, 1f, 1f);
    }
}

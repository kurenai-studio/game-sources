using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class UI : MonoBehaviour
{
    public GameObject loading_screen;
    public GameObject breakings_list_screen;
    public GameObject breaking_alert_prefab;
    public GameObject hp_bar;
    public GameObject timer;

    private List<GameObject> breaking_alerts = new List<GameObject>();

    void Start()
    {
        G.ModeChanged += OnModeChanged;
        G.BreakingUpdated += OnBreakingUpdated;
        G.PlayerDamaged += OnPlayerDamaged;
        OnBreakingUpdated();
        hp_bar.transform.Find("red").GetComponent<RectTransform>().localScale = new Vector3(G.player.GetComponent<Player>().hp / G.player.GetComponent<Player>().max_hp, 1f, 1f);
        hp_bar.transform.Find("white").GetComponent<RectTransform>().localScale = new Vector3(G.player.GetComponent<Player>().hp / G.player.GetComponent<Player>().max_hp, 1f, 1f);
    }

    private void Update()
    {
        timer.GetComponent<TextMeshProUGUI>().text = "Oxygen: " + (G.MAIN_TIME - G.main_timer).ToString("F1");
    }

    private void OnModeChanged()
    {
        loading_screen.GetComponent<Animator>().SetBool("isNeedDarkening", true);
    }

    private void OnBreakingUpdated()
    {
        foreach (var breaking_alert in breaking_alerts)
            Destroy(breaking_alert);
        breaking_alerts.Clear();

        GameObject breakings_list = breakings_list_screen.transform.Find("BreakingsList").gameObject;

        const float y_spread = -120f;
        float curr_y_spread = 0f;

        foreach (var breaking in G.breakings)
        {
            GameObject breaking_alert = Instantiate(breaking_alert_prefab, breakings_list.transform);
            breaking_alert.GetComponent<RectTransform>().anchoredPosition  = new Vector2(50f, curr_y_spread - 50f);
            string alert_text = "";
            switch (breaking)
            {
                case Main2.BreakingType.OnBoardComputer:
                    alert_text = "On-board computer is broken";
                    break;
                case Main2.BreakingType.Accelerometer:
                    alert_text = "Accelerometer is broken";
                    break;
                case Main2.BreakingType.FeedFishes:
                    alert_text = "Fish need food";
                    break;
                case Main2.BreakingType.SensorCalibration:
                    alert_text = "Sensors require calibration";
                    break;
                default:
                    break;
            }
            breaking_alert.transform.Find("AlertText").GetComponent<TextMeshProUGUI>().text = alert_text;

            breaking_alerts.Add(breaking_alert);

            curr_y_spread += y_spread;
        }
    }

    private void OnPlayerDamaged()
    {
        float initial_x_scale = hp_bar.transform.Find("red").GetComponent<RectTransform>().localScale.x;
        float goal_x_scale = G.player.GetComponent<Player>().hp / G.player.GetComponent<Player>().max_hp;
        hp_bar.transform.Find("red").GetComponent<RectTransform>().localScale = new Vector3(goal_x_scale, 1f, 1f);
        StartCoroutine(WhiteHPTrail(initial_x_scale, goal_x_scale, 0.5f));
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

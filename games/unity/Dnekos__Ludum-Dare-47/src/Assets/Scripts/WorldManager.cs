using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class WorldManager : MonoBehaviour
{
    [SerializeField]
    GameObject ProductionTab, UpgradeTab, ResearchTab, EndTab, endgame;
    [SerializeField]
    Text Countdown;

    bool game_end = false;

    public static float currenttime = 15;
    // Start is called before the first frame update

    // Update is called once per frame
    void Update()
    {
        // Tab Unlocks
        if (PlayerManager.Inst.unlocked_Production)
            ProductionTab.SetActive(true);
        if (PlayerManager.Inst.unlocked_Upgrades)
            UpgradeTab.SetActive(true);
        if (PlayerManager.Inst.unlocked_tokens)
            ResearchTab.SetActive(true);

        // timer display
        if (currenttime < 10) // if ten seconds left, turn red
            Countdown.color = Color.red;
        if (currenttime < 10 || PlayerManager.Inst.unlocked_tokens) // show timer all the time if EotW happened or ten seconds before
        {
            if (currenttime > 0)
            {
                float minutes = Mathf.FloorToInt(currenttime / 60);
                float seconds = Mathf.FloorToInt(currenttime % 60);
                Countdown.text = string.Format("{0:00}:{1:00}", minutes, seconds);
            }
            else
                Countdown.text = "00:00"; // cap it at 0
        }
        else
        {
            Countdown.text = "";
        }

        if (currenttime > 0)
        {
            currenttime -= Time.deltaTime;
            //Debug.Log(currenttime);
        }
        else if (endgame.activeSelf == false)
        {
            EndTab.SetActive(true);
            EndTab.transform.SetAsLastSibling();

            EndTab.transform.GetComponentInChildren<Text>().text = "You recieve " + (int)Mathf.Pow((float)PlayerManager.Inst.money * 0.2f, 0.8f) + " Crystalized Milk";
        }
    }
    public void EndTheWorld()
    {
        PlayerManager.Inst.Reset();
    }

    public void WinGame()
    {
        SceneManager.LoadScene(2);
    }

    public void Escape()
    {
        currenttime = 0;

        endgame.SetActive(true);
        endgame.transform.SetAsLastSibling();
    }

    public void GoToTab()
    {
        UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.transform.parent.SetAsLastSibling();
    }
}

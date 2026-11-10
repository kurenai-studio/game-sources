using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIController : MonoBehaviour
{
    public Text resources;
    public Text power;
    public Text bots;

    public static UIController instance;

    public void Awake()
    {
        if (instance == null)
        {
            instance = this;
        }
        else if (instance != this)
        {
            Destroy(gameObject);
            DontDestroyOnLoad(gameObject);
        }
    }

    void Start()
    {
        resources.text = GameController.instance.resources.ToString();
        power.text = GameController.instance.power.ToString();
        bots.text = GameController.instance.botsAvailable.ToString();
    }

    public void UpdateBots()
    {
        bots.text = GameController.instance.botsAvailable.ToString();
    }

    public void UpdateResources()
    {
        resources.text = GameController.instance.resources.ToString();
    }

    public void UpdatePower()
    {
        power.text = GameController.instance.power.ToString();
    }
}

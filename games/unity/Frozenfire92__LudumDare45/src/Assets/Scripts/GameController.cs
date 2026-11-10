using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameController : MonoBehaviour
{
    public static GameController instance;

    public GameObject bot;
    public int resources = 0;
    public int power = 0;
    public int botCollectionSpeed = 1;
    public int botsAvailable = 1;
    public int botPowerUsage = 1;
    public int buildingCost = 20;

    private void Awake()
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

    private void Start()
    {
        ObjectPooler.instance.CreatePool(bot, typeof(Bot));
    }

    public void SendBot(GameObject target)
    {
        if (botsAvailable > 0)
        {
            float miningTime = Random.Range(5f, 20f);
            int powerNeeded = (int)(miningTime * botPowerUsage);

            if (power >= powerNeeded)
            {
                botsAvailable--;
                power -= powerNeeded;
                UIController.instance.UpdateBots();
                UIController.instance.UpdatePower();
                GameObject bot = ObjectPooler.instance.GetObject(typeof(Bot));
                Bot b = bot.GetComponent<Bot>();
                b.target = target;
                b.Move(target.transform);
                b.StartBeam(miningTime);
            }
            else
            {
                Debug.Log("TODO notify not enough power");
            }
        }
    }
}

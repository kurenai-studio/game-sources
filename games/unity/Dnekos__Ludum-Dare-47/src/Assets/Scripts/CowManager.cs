using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CowManager : MonoBehaviour
{

    [SerializeField]
    int PurchasableIndex = 0;
    public float timeleft = 0f;
    int charging_cows = 0;

    [SerializeField]
    GameObject Toggler;
    
    Text buttontxt,bartxt;
    Transform bartransform;

    // Start is called before the first frame update
    void Start()
    {
        buttontxt = transform.GetChild(0).GetComponent<Text>();
        bartransform = transform.GetChild(1).GetChild(0).transform;
        bartxt = transform.GetChild(1).GetChild(1).GetComponent<Text>();
        //bartxt.text = "All " + PlayerManager.Inst.purchases[PurchasableIndex].Name + "s refilled";
    }


    // Update is called once per frame
    void Update()
    {
        if (PlayerManager.Inst.unlocked_milk && Toggler)
        {
            Toggler.SetActive(true);
        }

        Workspace item = (Workspace)PlayerManager.Inst.purchases[PurchasableIndex];

        bartxt.text = "All " + item.Name + "s refilled"; // set done text
        int available_cows = item.Available;
        float max_time = item.recharge_time;
        if (timeleft > 0)
        {
            timeleft -= Time.deltaTime; // decrease time
            bartxt.text = Mathf.Floor(timeleft / max_time * 100) + "%"; // update time counter

            if (timeleft <= 0) // if filled
            {
                charging_cows--; // add cow back to available pool
                if (charging_cows > 0) // restart timer if needed
                    timeleft = max_time;
            }
        }


        buttontxt.text = item.actionphrase + "\n" +
            (available_cows - charging_cows) + "/" + available_cows; // update amount of available cows
        if (item.milkcost != 0)
        {
            buttontxt.text += "\nCost: " + item.milkcost + " Milk";
        }

        bartransform.localScale = new Vector3( (max_time - timeleft) / max_time, bartransform.localScale.y, bartransform.localScale.z); // charge bar fill
    }

    public void ProduceClick()
    {
        Workspace item = (Workspace)PlayerManager.Inst.purchases[PurchasableIndex];
        if (charging_cows < item.Available && item.milkcost <= PlayerManager.Inst.milk)//new Currency((item.milkcost)))
        {
            PlayerManager.Inst.milk = PlayerManager.Inst.milk - item.milkcost;//new Currency((float)item.milkcost); 

            if (timeleft <= 0) // only reset bar is not actively charging
                timeleft = item.recharge_time; // start charge

            charging_cows++; // another cow needs recharging
            if (item.making_milk)
                PlayerManager.Inst.milk += item.value;
            else
                PlayerManager.Inst.money += item.value; // add value;
        }
    }
   
    public void ToggleMilk(bool tog)
    {
        Workspace item = (Workspace)PlayerManager.Inst.purchases[PurchasableIndex];

        item.making_milk = tog;
    }
}

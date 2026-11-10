using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class InfoManager : MonoBehaviour
{
    [SerializeField]
    GameObject Production, Upgrade, EotW, Research;
    Text Textbox, TextTitle;

    private void Start()
    {
        Textbox = GetComponent<Text>();
        TextTitle = transform.GetChild(0).GetComponent<Text>();
    }

    // Update is called once per frame
    void Update()
    {
        if (PlayerManager.Inst.unlocked_Production)
            Production.SetActive(true);
        if (PlayerManager.Inst.unlocked_Upgrades)
            Upgrade.SetActive(true);
        if (PlayerManager.Inst.tokens > 0)
        {
            EotW.SetActive(true);
            Research.SetActive(true);
        }
    }

    public void ShowInfo(int info)
    {
        switch (info)
        {
            case 0:
                TextTitle.text = "Farmyard";
                Textbox.text = "The Farmyard is where all of your Acquisitions stay, and is your primary source of income. Click on one of the bars to use one of that Acquisition, giving you some Money or Milk.\nWhen used, that Acquisition must recharge, but if you have multiple you can click again to use on of the others you have.\nMilk can only be gotten from Cows or Goats, and are used to fuel later Acquisitions, which give you more money than Milk producers. An Acquisition can only produce Milk OR Money at a time.";
                break;
            case 1:
                TextTitle.text = "Acquisitions";
                Textbox.text = "The Acquisitions tab is where you can buy more Acquisitions. It may look empty at the beginning but more options unlock automatically.\nEach Acquisition's cost increases by a multiplier dependant on the type.";
                break;
            case 2:
                TextTitle.text = "Production";
                Textbox.text = "The Production tab is where you can buy and manage Farmhands. These hardworking boys can be given a singular Acquisition to manage, running it automatically and independantly from the Farmyard.\nThey will autoclick and get the profits to you. As they work independantly, you can have multiple Acquisitions recharging at the same time with Farmhands!";
                break;
            case 3:
                TextTitle.text = "Upgrades";
                Textbox.text = "Here you can purchase Upgrades!\nThese upgrades increase an aspect of an Acquistion or the Farmhands by the shown multiplier. Upgrades unlock automatically as you buy more Acquisitions and Upgrades. They alo only last for one world.\nFor math nerds, the equation for an upgrade's cost is: (Price of 5th Acquisition of type * 2.5)^0.8";
                break;
            case 4:
                TextTitle.text = "The End of the World";
                Textbox.text = "Oh No! The Apocalypse!\nLuckily for you, it seems the dairy gods have taken a liking to you and given you another chance at life, returning you to 90 seconds before the world ends, with the extra gift of some Crystalized Milk.\nEverything resets except tab unlocks, Research, and Crystalized Milk.";
                break;
            case 5:
                TextTitle.text = "Research";
                Textbox.text = "Here you can spend some Crystalized Milk to unlock the powers of time travel and bring some of your stuff to the next world.";
                break;
        }
    }
}

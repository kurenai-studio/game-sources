using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Collections.Generic;

public class Crafting : MonoBehaviour {

    static string[] bases = { "Missile", "Shell" };
    static string[] effects = { "EMP", "Explosive" };
    static string[] detonators = { "Impact", "Timer", "Remote" };
    static string[] augmentors = { "Hardened batteries", "Acid" };

    public GameObject[] prefabs;
    
    int[] selection = new int[4];

    public Text text;

    void OnEnable()
    {
        buildList();
    }

    public void SelectBase(int i)
    {
        if (i > bases.Length || i < 1)
            selection[0] = 0;
        else
            selection[0] = i;
        buildList();
    }
    public void SelectEffect(int i)
    {
        if (i > effects.Length || i < 1)
            selection[1] = 0;
        else
            selection[1] = i;
        buildList();
    }
    public void SelectDetonator(int i)
    {
        if (i > detonators.Length || i < 1)
            selection[2] = 0;
        else
            selection[2] = i;
        buildList();
    }
    public void SelectAugmentor(int i)
    {
        if (i > augmentors.Length || i < 1)
            selection[3] = 0;
        else
            selection[3] = i;
        buildList();
    }

    void buildList()
    {
        text.text = "";
        for (int i = 0; i < selection.Length; i++ )
        {
            if (selection[i] != 0)
            {
                switch (i)
                {
                    case 0:
                        text.text += "* " + bases[selection[i]-1]+"\n";
                        break;
                    case 1:
                        text.text += "* " + effects[selection[i] - 1] + "\n";
                        break;
                    case 2:
                        text.text += "* " + detonators[selection[i] - 1] + "\n";
                        break;
                    case 3:
                        text.text += "* " + augmentors[selection[i] - 1];
                        break;
                }
            }
        }
    }

    public void Craft()
    {
        if (selection[0] != 0 && selection[1] != 0 && selection[2] != 0)
        {
            string name = selection[0] == 1 ? "Missile" : "Shell";
            name += " " + selection[1];
            name += " " + selection[2];
            name += " " + selection[3];

            for (int i = 0; i < prefabs.Length; i++)
            {
                if (prefabs[i].name == name)
                {
                    GameObject.FindObjectOfType<GamestateManager>().bomb = prefabs[i];
                    text.text += "\n\nSuccessfully crafted item and loaded on to fighter";
                    return;
                }
            }

        }
        text.text += "Crafting failed";
    }
}

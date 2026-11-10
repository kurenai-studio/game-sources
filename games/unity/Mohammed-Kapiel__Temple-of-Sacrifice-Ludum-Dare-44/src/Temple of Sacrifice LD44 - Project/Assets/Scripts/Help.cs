using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Help : MonoBehaviour
{
    public List<GameObject> tooltips;
    public GameObject helpPanel;

    public GameObject toolTipParent;
    public int currTip = 0;

    private void Start()
    {

        tooltips = new List<GameObject>();

        foreach (Transform child in toolTipParent.transform)
        {
            tooltips.Add(child.gameObject);
        }
    }

    public void NextTip()
    {
        if(currTip == 0)
        {
            helpPanel.SetActive(true);
        }
            if (currTip + 1 < tooltips.Count)
            {

                tooltips[currTip].SetActive(false);
                tooltips[currTip + 1].SetActive(true);
                currTip++;
            }
            else
            {
                tooltips[currTip].SetActive(false);
                helpPanel.SetActive(false);
                currTip = 0;
            }
    }
}

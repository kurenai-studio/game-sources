using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorkspaceManager : MonoBehaviour
{
    // Update is called once per frame
    void Update()
    {
        for(int i = 0; i < transform.childCount;i++)
        {
            if (PlayerManager.Inst.purchases[i].quantity > 0)
                transform.GetChild(i).gameObject.SetActive(true);
            else
                transform.GetChild(i).gameObject.SetActive(false);
        }
    }
}

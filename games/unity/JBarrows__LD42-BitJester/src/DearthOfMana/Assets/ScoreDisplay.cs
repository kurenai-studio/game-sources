using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class ScoreDisplay : UIBehaviour {

    public void SetText(string t)
    {
        GetComponent<Text>().text = t;
    }
}

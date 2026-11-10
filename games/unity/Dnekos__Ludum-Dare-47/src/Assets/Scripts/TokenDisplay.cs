using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class TokenDisplay : MonoBehaviour
{

    // Update is called once per frame
    void Update()
    {
        if (PlayerManager.Inst.unlocked_tokens)
            GetComponent<Text>().text = PlayerManager.Inst.tokens + " Pieces of Crystalized Milk";
    }
}

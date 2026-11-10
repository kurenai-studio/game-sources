using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Building : MonoBehaviour
{
    void Start()
    {
        StartCoroutine(PowerGeneration());
    }

    IEnumerator PowerGeneration()
    {
        while (true)
        {
            yield return new WaitForSeconds(3f);
            GameController.instance.power++;
            UIController.instance.UpdatePower();
        }
    }
}

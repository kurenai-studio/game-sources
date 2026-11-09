using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimedDisable : MonoBehaviour
{
    public float time = 2f;

    WaitForSeconds wfs;

    private void Awake() {
        wfs = new WaitForSeconds(time);
        gameObject.SetActive(false);
    }
    
    IEnumerator DelayedDisable() {
        yield return wfs;
        gameObject.SetActive(false);
    }

    private void OnEnable() {
        StartCoroutine(DelayedDisable());
    }
}

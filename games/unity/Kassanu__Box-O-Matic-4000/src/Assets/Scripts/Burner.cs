using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Burner : MonoBehaviour {

    [SerializeField]
    GameObject flameBurstEffect;

    public void triggerFlameBurst() {
        if (!this.flameBurstEffect.activeSelf) {
            StartCoroutine(PulseBurstEffect(2));
        }
    }

    private IEnumerator PulseBurstEffect(float duration) {
        this.flameBurstEffect.SetActive(true);
        yield return new WaitForSeconds(duration);
        this.flameBurstEffect.SetActive(false);
    }

}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DestroyAfter : MonoBehaviour
{
    public float time = 5f;
    public bool disable = false;

    private void OnEnable()
    {
        if (disable)
            StartCoroutine(Utils.Delay(()=> gameObject.SetActive(false), time));
        else
            StartCoroutine(Utils.Delay(()=> Destroy(gameObject), time));
    }
}

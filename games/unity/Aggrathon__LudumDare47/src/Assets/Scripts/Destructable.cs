using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Destructable : MonoBehaviour
{
    public GameObject deathFX;
    public Vector3 fxOffset;
    public bool resetPosition;

    Vector3 origPos;

    private void Awake()
    {
        origPos = transform.position;
    }

    private void Start()
    {
        if (GameManager.instance)
            GameManager.instance.RegisterRespawn(this);
    }

    public void Die()
    {
        if (deathFX)
            Instantiate(deathFX, transform.position + fxOffset, transform.rotation);
        gameObject.SetActive(false);
    }

    private void OnEnable()
    {
        if (resetPosition)
            transform.position = origPos;
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PersistentOne : MonoBehaviour
{
    static PersistentOne instance;

    void Start()
    {
        if (instance == null)
        {
            DontDestroyOnLoad(this);
            instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    private void OnDestroy()
    {
        if (instance == this)
            instance = null;
    }
}

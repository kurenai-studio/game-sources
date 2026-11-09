using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class PersistantMusic : MonoBehaviour
{
    static bool alreadySpawned = false;

    private void Awake() {
        if (alreadySpawned) {
            Destroy(gameObject);
        } else {
            alreadySpawned = true;
            DontDestroyOnLoad(gameObject);
        }
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Despawner : MonoBehaviour {

    [SerializeField] GameController gc;

    private void OnTriggerEnter(Collider other)
    {
        if(other.gameObject.tag == "Zombie")
        {
            print("Zombie Entered");
            gc.ZombieReachedEnd();
        }
        Destroy(other.gameObject);
        print("Trigger Entered");
    }
}

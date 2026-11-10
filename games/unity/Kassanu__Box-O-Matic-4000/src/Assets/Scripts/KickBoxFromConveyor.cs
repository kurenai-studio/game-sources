using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KickBoxFromConveyor : MonoBehaviour {

    [SerializeField]
    Conveyor conveyor;

    void OnTriggerEnter2D(Collider2D collision) {
        if (collision.tag == "Box") {
            Box box = collision.gameObject.GetComponent<Box>();
            if (box.OnConveyor) {
                box.OnConveyor = false;
                box.transform.SetParent(null);
                float ks = conveyor.RandomKickStrength();
                Debug.Log("kicking");
                Debug.Log("Stren: " + ks);
                box.Throw(new Vector2(ks, 0));
            }
        }
    }
}

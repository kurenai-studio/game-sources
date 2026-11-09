using DefaultNamespace;
using UnityEngine;

public class Pointer : MonoBehaviour {
    void Start() {
        Cursor.visible = false;
    }

    void FixedUpdate() {
        var pos = Utils.MouseInWorld();
        pos.z = 500f;
        transform.position = pos;
    }
}
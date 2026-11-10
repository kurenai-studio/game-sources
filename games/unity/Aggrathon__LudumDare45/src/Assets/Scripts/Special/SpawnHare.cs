using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpawnHare : MonoBehaviour
{
    public Unit hare;

    private void Start() {
        var pl = FindObjectOfType<PlayerManager>();
        var bd = FindObjectOfType<Board>();
        var bt = bd.FindBest((BoardTarget b) => (b.transform.position.sqrMagnitude, true));
        var un = Instantiate<Unit>(hare, bt.transform.position, Quaternion.identity);
        un.Setup(pl.GetComponent<DeckManager>(), bt);
        un.hasMoved = false;
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerChargeBar : MonoBehaviour {

    public GameObject chargeBar;
    public Player player;

    void Update() {
        chargeBar.transform.localScale = new Vector3(player.getChargePercent(), chargeBar.transform.localScale.y, 0);
    }
}

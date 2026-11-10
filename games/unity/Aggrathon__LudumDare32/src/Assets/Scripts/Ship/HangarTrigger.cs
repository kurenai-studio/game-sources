using UnityEngine;

public class HangarTrigger : MonoBehaviour {


    public void OnTriggerEnter(Collider col)
    {
        if (col.transform.tag == "Player")
            GameObject.FindObjectOfType<GamestateManager>().EnterBattleShip();
    }

}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ButtonScript : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void AddLevelHealthUp() {
        if (ShopBehaviour.clickable[0]) {
            GameObject player = GameObject.FindGameObjectWithTag("Player");
            player.GetComponent<Player>().IncrementPlayerAbilityLevel(0);
            player.GetComponent<Player>().TakeDamage(GameObject.FindGameObjectWithTag("UI_Shop_Canvas").GetComponent<ShopBehaviour>().HealthUpCost);
        }
    }

    public void AddLevelSpeedUp() {
        if (ShopBehaviour.clickable[1]) {
            GameObject player = GameObject.FindGameObjectWithTag("Player");
            player.GetComponent<Player>().IncrementPlayerAbilityLevel(1);
            player.GetComponent<Player>().TakeDamage(GameObject.FindGameObjectWithTag("UI_Shop_Canvas").GetComponent<ShopBehaviour>().SpeedUpCost);
        }
    }

    public void AddLevelResistanceUp() {
        if (ShopBehaviour.clickable[2]) {
            GameObject player = GameObject.FindGameObjectWithTag("Player");
            player.GetComponent<Player>().IncrementPlayerAbilityLevel(2);
            player.GetComponent<Player>().TakeDamage(GameObject.FindGameObjectWithTag("UI_Shop_Canvas").GetComponent<ShopBehaviour>().ResistanceUpCost);
        }
    }

    public void AddLevelDrainDown() {
        if (ShopBehaviour.clickable[3] && Global.GetEPS() > 0) {
            GameObject player = GameObject.FindGameObjectWithTag("Player");
            player.GetComponent<Player>().IncrementPlayerAbilityLevel(3);
            player.GetComponent<Player>().TakeDamage(GameObject.FindGameObjectWithTag("UI_Shop_Canvas").GetComponent<ShopBehaviour>().EPSDownCost);
            Global.DecreaseEPS();
        }
    }
}

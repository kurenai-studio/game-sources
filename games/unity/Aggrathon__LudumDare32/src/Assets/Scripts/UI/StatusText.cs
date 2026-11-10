using UnityEngine;
using UnityEngine.UI;
using System.Collections;

[RequireComponent(typeof(Text))]
public class StatusText : MonoBehaviour {

    Text text;

    string[] texts;

    int energy = 0;
    int hull = 0;

    ShipHealth health;
    Forcefield shields;

	// Use this for initialization
	void Start () {
        text = GetComponent<Text>();
        foreach (ShipHealth sh in GameObject.FindObjectsOfType<ShipHealth>())
            if (!sh.Enemy)
                health = sh;
        shields = health.gameObject.GetComponentInChildren<Forcefield>();
        texts = text.text.Split('*');
	}

    void Update()
    {
        int newenergy = (int)(shields.getShieldEnergyPercent()*100);
        int newhull = (int)(health.getHealthPercent()*100);

        if (newenergy != energy || newhull != hull)
        {
            hull = newhull;
            energy = newenergy;
            string ener = (energy == 0f ? "<color=red>Offline</color>" : energy+"%");
            text.text = texts[0] + ener + texts[1] + hull+"%" + texts[2];
        }
	}
}

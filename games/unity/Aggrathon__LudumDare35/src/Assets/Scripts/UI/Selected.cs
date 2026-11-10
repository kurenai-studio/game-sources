using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

public class Selected : MonoBehaviour {

	GameData data;

	int active = 0;
	List<Image> icons;

	void Start () {
		data = GameData.instance;
		icons = new List<Image>();
		icons.Add(transform.GetChild(0).GetComponent<Image>());
	}
	
	void Update () {
		int i;
		if(data.playerTeam.selectedUnits.Count > icons.Count)
		{
			for (i = icons.Count; i < data.playerTeam.selectedUnits.Count; i++)
			{
				GameObject go = GameObject.Instantiate(transform.GetChild(0).gameObject) as GameObject;
				go.transform.SetParent(transform);
				icons.Add(go.GetComponent<Image>());
			}
		}
		for (i = 0; i < data.playerTeam.selectedUnits.Count; i++)
		{
			Unit u = data.playerTeam.selectedUnits[i];
			icons[i].sprite = u.type.icon;
			if(u.health<1f)
				icons[i].color = Color.black;
			else
				icons[i].color = Color.Lerp(Color.red, Color.green, u.health/u.type.health);
		}
		if(active != i)
		{
			for (; i < active; i++)
			{
				icons[i].gameObject.SetActive(false);
			}
			for (; active < i; active++)
			{
				icons[active].gameObject.SetActive(true);
			}
			active = data.playerTeam.selectedUnits.Count;
		}
	}
}

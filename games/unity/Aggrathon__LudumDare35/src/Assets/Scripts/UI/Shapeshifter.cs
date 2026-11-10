using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class Shapeshifter : MonoBehaviour {

	public UnitTypeList unitTypes;
	public TeamController teamController;
	
	void Start () {
		if(teamController == null)
		{
			teamController = GameObject.FindObjectOfType<TeamController>();
		}
		for (int i = 1; i < unitTypes.units.Length; i++)
		{
			(GameObject.Instantiate(transform.GetChild(0).gameObject) as GameObject).transform.SetParent(transform);
		}
		for (int i = 0; i < transform.childCount; i++)
		{
			int index = i;
			Transform button = transform.GetChild(i);
			button.GetComponent<Image>().sprite = unitTypes.types[i].icon;
			button.GetComponent<Button>().onClick.AddListener(() => { teamController.Shapeshift(index); });
			string popup = "<b><size=18>"+ unitTypes.types[i].name + "</size></b>\n" + unitTypes.types[i].description;
			button.GetComponentInChildren<Text>().text = popup;
			button.GetChild(0).gameObject.SetActive(false);
		}
	}
}

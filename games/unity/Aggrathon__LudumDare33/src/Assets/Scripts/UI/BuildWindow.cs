using UnityEngine;
using UnityEngine.UI;

public class BuildWindow : MonoBehaviour {

	public Transform buttonParent;
	public Text previewText;
	public Button buildButton;

	private Builder currentBuilder;
	private BuildingInfo currentBuilding;

	public void Start() {
		gameObject.SetActive(false);
	}

	public void Show(Builder bd) {
		if(buttonParent.childCount < bd.buildList.buildings.Count) {
			Debug.LogError("[BUILDWINDOW] Too few buttons in the buildwindow");
			return;
		}

		previewText.text = "Select a building";
		buildButton.interactable = false;

		currentBuilder = bd;
		currentBuilding = null;

		int i = 0;
		foreach (Transform child in buttonParent) {
			if(i < bd.buildList.buildings.Count) {
				child.gameObject.SetActive(true);
				child.GetChild(0).GetComponent<Text>().text = bd.buildList.buildings[i].name;
			} else {
				child.gameObject.SetActive(false);
			}
			i++;
		}

		transform.position = bd.transform.position;
		gameObject.SetActive(true);
	}

	public void Preview(int index) {
		buildButton.interactable = true;
		currentBuilding =  currentBuilder.buildList.buildings[index];
		previewText.text = "<b>"+currentBuilding.name+"</b>\t\t("+currentBuilding.cost+")\n"+currentBuilding.description;
	}

	public void Build() {
		if(currentBuilding == null) {
			buildButton.interactable = false;
			Debug.Log("[BUILDWINDOW] No building selected");
		}
		GameObject.Instantiate(currentBuilding.prefab, currentBuilder.transform.position, currentBuilder.transform.rotation);
		Destroy(currentBuilder.gameObject);
		Data.money.amount -= currentBuilding.cost;
		Data.ConstructionAt(currentBuilder.transform.position);
		currentBuilding = null;
		currentBuilder = null;
		gameObject.SetActive(false);
		UserInterface.DrawStats();
	}
}

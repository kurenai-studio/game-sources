using UnityEngine;
using System.Collections;

public class Builder : MonoBehaviour {

	public BuildList buildList;
	public bool unlocked = false;

	public void Start() {
		Data.AddBuilder(this);
		gameObject.SetActive(false);
	}

	public void ShowBuildWindow() {
		UserInterface.ShowBuildWindow(this);
	}

	void OnDestroy() {
		Data.RemoveBuilder(this);
	}
}

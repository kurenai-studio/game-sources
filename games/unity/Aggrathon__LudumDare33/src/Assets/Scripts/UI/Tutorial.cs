using UnityEngine;
using System.Collections;

public class Tutorial : MonoBehaviour, IOnSeasonChange {

	private bool shown = false;

	void Start () {
		Data.AddSeasonListener(this);
		gameObject.SetActive(false);
	}

	public void OnSeasonChange(Data.Seasons season) {
		if(Data.power.amount < 20) {
			gameObject.SetActive(true);
			shown = true;
		}
	}

	public void OnDisable() {
		if(shown) {
			Data.RemoveSeasonListener(this);
			Destroy(gameObject);
		}
	}
}

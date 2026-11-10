using UnityEngine;
using System.Collections;

public class SeasonActive : MonoBehaviour, IOnSeasonChange {

	public Data.Seasons season;

	void Start () {
		if(season != Data.Seasons.EverySeason) {
			Data.AddSeasonListener(this);
			OnSeasonChange(Data.season);
		}
	}

	public void OnSeasonChange(Data.Seasons ses) {
		if (season == ses) {
			gameObject.SetActive(true);
		} else {
			gameObject.SetActive(false);
		}
	}
}

using UnityEngine;
using System.Collections;

public class Road : MonoBehaviour {

	void Start () {
		Data.AddRoad(this);
		gameObject.SetActive(false);
	}
}

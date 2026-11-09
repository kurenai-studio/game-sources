using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ProgressionSwitch : MonoBehaviour {
	public string switchVar;
	public bool value;

	void Awake()
	{
		Update(); //activated/deactivate before anyone does anything
	}

	void Update () {
		if((bool) Global.GetValue(switchVar)){
			TurnChildren(value);
		}else{
			TurnChildren(!value);
		}
	}

	void TurnChildren(bool active){
		foreach(Transform child in transform){
			child.gameObject.SetActive(active);
		}
	}
}

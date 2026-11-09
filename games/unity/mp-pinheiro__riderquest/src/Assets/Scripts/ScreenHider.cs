using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScreenHider : MonoBehaviour {

	SpriteRenderer sp;
	static ScreenHider instance;
	void Awake () {
		instance = this;
		sp = GetComponent<SpriteRenderer>();
	}
	
	public static void HideScreen(){
		instance.sp.enabled = true;
	}
	
	public static void ShowScreen(){
		instance.sp.enabled = false;
	}
}

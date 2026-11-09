using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class NPC : MonoBehaviour {
	public string nameVar;
	public string dialog;

	void OnTriggerEnter2D(Collider2D other){
		if(other.tag=="Player"){
			StartCoroutine(StartDialog());
		}
	}

	IEnumerator StartDialog(){
		yield return MessageManager.ShowMessage((string) Global.GetValue(nameVar), dialog);
		/*
		yield return MessageManager.ShowMessage("Father", "Look who's finally up! Ready for our little adventure today, pal?");
		yield return MessageManager.ShowMessage("You" , "We are really going!?");
		//Time.timeScale = 1f;
		*/
	}
}

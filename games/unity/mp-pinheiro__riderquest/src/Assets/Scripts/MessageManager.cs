using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MessageManager : MonoBehaviour {

	public GameObject mBox;
	public Text mNameText;
	public Text mMsgText;
	public GameObject cBox;
	public Text cQstText;
	public Text[] cChcText;
	public Transform cCursor;
	static bool showingMessage;
	static bool showingChoices;
	new static string name;
	static string message;
	static string[] choices;
	static int currentChoice;
	static string chosenChoice;
	AudioSource cursorAudio;
	AudioSource selectAudio;
	AudioSource messageAudio;

	void Awake(){
		AudioSource[] audio = GetComponents<AudioSource>();
		cursorAudio = audio[0];
		selectAudio = audio[1];
		messageAudio = audio[2];
	}
	
	// Update is called once per frame
	void Update () {
		//message
		if(showingMessage){
			mNameText.text = name;
			mMsgText.text = message;
			mBox.SetActive(true);
			if(Input.GetKeyDown(KeyCode.Space)){
				messageAudio.Play();
				showingMessage = false;
			}
		}else{
			mBox.SetActive(false);
		}

		//choices
		if(showingChoices){
			cQstText.text = message;
			cBox.SetActive(true);

			//reset all choices
			for(int i=0; i<cChcText.Length; i++){
				cChcText[i].text = "";
			}

			//move cursor
			if(Input.GetKeyDown(KeyCode.LeftArrow)){
				cursorAudio.Play();
				--currentChoice;
				if(currentChoice<0) currentChoice += choices.Length;
			}
			if(Input.GetKeyDown(KeyCode.RightArrow)){
				cursorAudio.Play();
				++currentChoice;
				if(currentChoice>=choices.Length) currentChoice -= choices.Length;
			}
			if(Input.GetKeyDown(KeyCode.Space)){
				selectAudio.Play();
				chosenChoice = choices[currentChoice];
				showingChoices = false;
			}

			//set relevant choices
			float dist = 18f/(choices.Length+1);
			for(int i=0; i<choices.Length; i++){
				Vector3 pos = cChcText[i].transform.position;
				float x = -9f + dist*(i+1);
				cChcText[i].transform.position = new Vector3(
					x,
					pos.y,
					pos.z
				);
				cChcText[i].text = choices[i];
				if(currentChoice==i){
					cCursor.position = new Vector3(
						x,
						cCursor.position.y,
						cCursor.position.z
					);
				}
			}
		}else{
			cBox.SetActive(false);
		}
	}

	public static IEnumerator ShowMessage(string nm, string msg){
		return ShowMessage(nm, msg, true);
	}

	public static IEnumerator ShowMessage(string nm, string msg, bool stopTime){
		if(stopTime) Time.timeScale = 0f;
		showingMessage = true;
		name = nm;
		message = msg;
		if(stopTime){
			return new WaitWhile (()=> (MessageManager.IsShowingMessage() || ((Time.timeScale=1f)==0f)));
		}else{
			return new WaitWhile (()=> MessageManager.IsShowingMessage());
		}
	}

	public static void HideMessage(){
		showingMessage = false;
	}

	public static bool IsShowingMessage(){
		return showingMessage;
	}

	public static IEnumerator ShowChoices(string msg, string[] chc){
		Time.timeScale = 0f;
		showingChoices = true;
		message = msg;
		choices = chc;
		currentChoice = 0;
		return new WaitWhile (()=> (MessageManager.IsShowingChoices() || ((Time.timeScale=1f)==0f)));
	}

	public static bool IsShowingChoices(){
		return showingChoices;
	}

	public static string GetChosenChoice(){
		return chosenChoice;
	}
}


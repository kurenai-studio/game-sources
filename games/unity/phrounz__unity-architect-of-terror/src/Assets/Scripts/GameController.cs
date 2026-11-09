using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class GameController : MonoBehaviour {
	
	//--------
	// public objects
	
	public Texture textureTitle;
	public Texture textureTheEnd;
	public Texture texturePercent;
	public GameObject gameObjectPersonage;

	//--------
	// constants

	private const int NB_PERSONAGES = 100;

	private const int LIMIT_NAZIS_REQUIRED_FOR_MEETING = 10;
	private const int LIMIT_NAZIS_FOR_ATTACKS = 20;
	private const int LIMIT_NAZIS_SHOW_FLAG = 30;
	private const int LIMIT_NAZIS_FOR_PRISON = 60;
	private const int LIMIT_NAZIS_REQUIRED_TO_BLUE_YELLOW = 70;
	private const float DISTANCE_PRISON = 4f;
	private const float DURATION_BEGINNING_FADE = 5f;//seconds

	public enum GameMode { 
		GAME_MODE_NOTHING=0, GAME_MODE_TRIBUNE=1, GAME_MODE_ATTACKS=2, GAME_MODE_FLAG=3, GAME_MODE_PRISON=3, GAME_MODE_BLUE_YELLOW=4 };

	//--------
	// private stuff - initialized at start
	
	private TribuneController tribuneController = null;
	private GUIStyle guiStyle = new GUIStyle();
	//private GUIStyle guiStyleBigFront = new GUIStyle();
	private Texture2D textureBlack = null;

	//--------
	// private stuff
	
	private bool horribleMeeting1Done = false;
	private bool horribleMeeting2Done = false;
	private float m_timeEndBeginningFade = -1f;
	private float m_timeEndGameOver = -1f;
	
	//--------
	// private stuff - recounted at each frame

	private int countNotDead = 0;
	private int countNazis = 0;
	private int countNotVictims = 0;
	
	//--------
	// code
	
	// Use this for initialization
	void Start () {
		for (int i = 0; i < NB_PERSONAGES; ++i) {
			Vector3 pos = new Vector3((float)Random.Range(-10, 10), 1.0f, (float)Random.Range(-10, 10));
			Instantiate(gameObjectPersonage, pos, Quaternion.identity);
		}

		guiStyle.fontSize = 20;
		//guiStyleBigFront.fontSize = 60;
		//guiStyleBigFront.normal.textColor = Color.white;

		tribuneController = (TribuneController) GameObject.FindGameObjectWithTag("tribune").GetComponent(typeof(TribuneController));

		m_timeEndBeginningFade = Time.time + DURATION_BEGINNING_FADE;

		textureBlack = new Texture2D (1, 1);
		textureBlack.SetPixel (0, 0, new Color (0f, 0f, 0f, 1f));
		textureBlack.Apply ();
	}

	// Update is called once per frame
	void Update () {

		if (Input.GetKey (KeyCode.Escape)) {
			Application.Quit();
		}

		//-----------------------------------
		// count nazis

		countNotDead = 0;
		countNazis = 0;
		countNotVictims = 0;
		foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
			PersonageController script = (PersonageController) go.GetComponent(typeof(PersonageController));
			if (script != null && !script.isDead()) {
				countNotDead++;
				if (!script.isVictim()) {
					countNotVictims++;
					if (script.isNazi())
						countNazis++;
				}
			}
		}
		
		//-----------------------------------
		// tribune mode

		if (tribuneController.isPlayerOnTribune ()) {

			if (getGameMode()>=GameMode.GAME_MODE_BLUE_YELLOW) horribleMeeting1Done = true;
			if (getGameMode()>=GameMode.GAME_MODE_PRISON) horribleMeeting2Done = true;

			// nazis raise hand + listen to bullshit
			foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
				PersonageController script3 = (PersonageController) go.GetComponent(typeof(PersonageController));
				if (script3 != null && script3.isNazi()) {
					script3.listenToBullshit();
				}
			}
		}

		//-----------------------------------
		// attack mode
		
		if (getGameMode() >= GameMode.GAME_MODE_ATTACKS) {

			if (!tribuneController.isPlayerOnTribune()) {
				
				List<GameObject> victims = new List<GameObject>();
				
				// get list of victims
				foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
					PersonageController script2 = (PersonageController) go.GetComponent(typeof(PersonageController));
					if (script2 != null && script2.isVictim() && !script2.isInPrison())
						victims.Add(go);
				}
				
				// very nazi personages attack random victims
				if (victims.Count > 0) {
					foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
						PersonageController script2 = (PersonageController) go.GetComponent(typeof(PersonageController));
						if (script2 != null && script2.isVeryNazi() && !script2.isVictim()) {
							script2.setIrrecoverableNazi();
							if (!script2.isTargetVictimSet()) {
								int randomVictim = Random.Range(0, victims.Count);
								PersonageController scriptTmp = 
									(PersonageController) victims[randomVictim].GetComponent(typeof(PersonageController));
								Debug.Assert (!scriptTmp.isInPrison());
								script2.setTargetVictim(victims[randomVictim]);
							}
						}
					}
				}
				
				// very nazi personages stop attack if victims are in prison or are dead
				foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
					PersonageController script2 = (PersonageController) go.GetComponent(typeof(PersonageController));
					if (script2.isNazi() && !script2.isVictim() && script2.isTargetVictimSet()) {
						PersonageController scriptTmp = (PersonageController)script2.getTargetVictim().GetComponent (typeof(PersonageController));
						if (scriptTmp != null && (scriptTmp.isInPrison () || scriptTmp.isDead())) {
							script2.setWandering ();
						}
					}
				}

			}
		}

		//-----------------------------------
		// prison mode

		if (isModePrison()) {

			List<PersonageController> nazisScripts = new List<PersonageController>();
			
			// get list of very nazis
			foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
				PersonageController script2 = (PersonageController) go.GetComponent(typeof(PersonageController));
				if (script2 != null && script2.isVeryNazi())
					nazisScripts.Add(script2);
			}

			// Move victims to the prison
			foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
				PersonageController script3 = (PersonageController)go.GetComponent (typeof(PersonageController));
				if (script3 != null) {
					if (script3.isVictim ()) {

						if (script3.getDistanceToPrison () < DISTANCE_PRISON || script3.isInPrison()) {
							script3.setInPrison ();
							script3.setTargetPrison();

						} else {

							bool hasEnemyNear = false;
							foreach (PersonageController naziScript in nazisScripts) {
								if (naziScript.getTargetVictim() == go && naziScript.getDistanceTo(go.transform.position) < 1f) {
									hasEnemyNear = true;
									break;
								}
							}
							if (hasEnemyNear)
								script3.setTargetPrison();
							else
								script3.setWandering();
						}
						//go.GetComponent<Rigidbody>().useGravity = true;
					} else {
						if (script3.getDistanceToPrison () < DISTANCE_PRISON) {
							Vector3 prisonPos = GameObject.FindGameObjectWithTag ("prison").transform.position + new Vector3 (0f, 1f, 0f);
							go.transform.position += (prisonPos - go.transform.position) * -1f * Time.deltaTime;
						}
					}
				}
			}
		}

		//-----------------------------------

		if (countNotDead == 0 && m_timeEndGameOver==-1) {
			m_timeEndGameOver = Time.time + DURATION_BEGINNING_FADE;
		}
	}

	public int getNbNazis() {
		return countNazis;
	}

	/*public int getNbForNextStep() {
		int limit = -1;
		if      (getGameMode()==GameMode.GAME_MODE_NOTHING)		limit = LIMIT_NAZIS_REQUIRED_FOR_MEETING;
		else if (getGameMode()==GameMode.GAME_MODE_TRIBUNE) 	limit = LIMIT_NAZIS_FOR_ATTACKS;
		else if (getGameMode()==GameMode.GAME_MODE_ATTACKS) 	limit = LIMIT_NAZIS_SHOW_FLAG;
		else if (getGameMode()==GameMode.GAME_MODE_FLAG) 		limit = LIMIT_NAZIS_FOR_PRISON;
		else if (getGameMode()==GameMode.GAME_MODE_PRISON) 		limit = LIMIT_NAZIS_REQUIRED_TO_BLUE_YELLOW;
		else if (getGameMode()==GameMode.GAME_MODE_BLUE_YELLOW) limit = -1;
		return limit * countNotVictims / NB_PERSONAGES;
	}*/

	public int getNbForTribune() { return LIMIT_NAZIS_REQUIRED_FOR_MEETING * countNotVictims / NB_PERSONAGES; }

	public GameMode getGameMode() {
		if (countNotVictims > 0) {
			int ct = countNazis * NB_PERSONAGES / countNotVictims;
			if (ct < LIMIT_NAZIS_REQUIRED_FOR_MEETING)
				return GameMode.GAME_MODE_NOTHING;
			else if (ct >= LIMIT_NAZIS_REQUIRED_FOR_MEETING && ct < LIMIT_NAZIS_FOR_ATTACKS)
				return GameMode.GAME_MODE_TRIBUNE;
			else if (ct >= LIMIT_NAZIS_FOR_ATTACKS && ct < LIMIT_NAZIS_SHOW_FLAG)
				return GameMode.GAME_MODE_ATTACKS;
			else if (ct >= LIMIT_NAZIS_SHOW_FLAG && ct < LIMIT_NAZIS_FOR_PRISON)
				return GameMode.GAME_MODE_FLAG;
			else if (ct >= LIMIT_NAZIS_FOR_PRISON && ct < LIMIT_NAZIS_REQUIRED_TO_BLUE_YELLOW)
				return GameMode.GAME_MODE_PRISON;
			else if (ct >= LIMIT_NAZIS_REQUIRED_TO_BLUE_YELLOW)
				return GameMode.GAME_MODE_BLUE_YELLOW;
			Debug.Assert (false);
		}
		return 0;
	}

	//public int getNbNazisRequiredForTribune() { return LIMIT_NAZIS_REQUIRED_FOR_MEETING*countNotVictims/NB_PERSONAGES; } 
	//public bool isModeMeetingOk() { return countNazis*100/countNotVictims >= LIMIT_NAZIS_REQUIRED_FOR_MEETING; }

	//public bool isModeAttackOk() { return countNazis*100/countNotVictims >= LIMIT_NAZIS_FOR_ATTACKS; }
	//public bool isModeShowFlag() { return countNazis*100/countNotVictims >= LIMIT_NAZIS_SHOW_FLAG; }
	public bool isModePrison() { return getGameMode() >= GameMode.GAME_MODE_PRISON && horribleMeeting2Done; }
	public bool isModeBlueEqualYellow() { return getGameMode() >= GameMode.GAME_MODE_BLUE_YELLOW && horribleMeeting1Done; }
	//public bool isModeBlueEqualYellowAllowMeeting() { return countNazis*NB_PERSONAGES/countNotVictims >= LIMIT_NAZIS_REQUIRED_TO_BLUE_YELLOW; }

	private void OnGUI() {
		if (Time.time < m_timeEndBeginningFade) {
			float ratio = (m_timeEndBeginningFade - Time.time) / DURATION_BEGINNING_FADE;
			Texture2D textureBlackSemi = new Texture2D (1, 1);
			textureBlackSemi.SetPixel (0, 0, new Color (0f, 0f, 0f, ratio));
			textureBlackSemi.Apply ();
			GUI.skin.box.normal.background = textureBlackSemi;
			GUI.Box (new Rect (0, 0, Screen.width, Screen.height), GUIContent.none);

			//GUI.Label (new Rect (10, 10, Screen.width, Screen.height), "Architect Of Terror", guiStyleBigFront);
			GUI.DrawTexture (new Rect (
				Screen.width/2 - textureTitle.width/2, Screen.height/2 - textureTitle.height/2, textureTitle.width, textureTitle.height), 
				textureTitle);

		} else if (m_timeEndGameOver != -1f) {
			float ratio = (m_timeEndGameOver - Time.time) / DURATION_BEGINNING_FADE;
			ratio = Mathf.Max (ratio, 0f);
			Texture2D textureBlackSemi = new Texture2D (1, 1);
			textureBlackSemi.SetPixel (0, 0, new Color (0f, 0f, 0f, 1f - ratio));
			textureBlackSemi.Apply ();
			GUI.skin.box.normal.background = textureBlackSemi;
			GUI.Box (new Rect (0, 0, Screen.width, Screen.height), GUIContent.none);

			//GUI.Label (new Rect (10, 10, Screen.width, Screen.height), "Architect Of Terror", guiStyleBigFront);
			GUI.DrawTexture (new Rect (
				Screen.width/2 - textureTheEnd.width/2, Screen.height/2 - textureTheEnd.height/2, textureTheEnd.width, textureTheEnd.height), 
				textureTheEnd);

			/*GUI.skin.box.normal.background = textureBlack;
			int level = 2;
			GUI.Box (new Rect (0, 0, 128*level, Screen.height), GUIContent.none);

			GUI.Label (new Rect (10, 10, Screen.width, Screen.height), "" + getNbNazis (), guiStyle);
			GUI.DrawTexture (new Rect (0,0,texturePercent.width, texturePercent.height), texturePercent);*/
		}
	}
}

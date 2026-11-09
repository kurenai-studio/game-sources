using UnityEngine;
using System.Collections;

public class TribuneController : MonoBehaviour {

	//--------
	// public objects

	public Texture textureBubbleNoLogo;
	public Texture textureBubbleNazi;
	public Texture textureBubbleAttackYellow;
	public Texture textureBubbleBlueEqualYellow;
	public Texture textureBubblePrison;

	//--------
	// private stuff - initialized at start

	private GameController gameControllerScript = null;
	private GUIStyle guiStyle = new GUIStyle();
	private Vector3 tribunePos;

	//--------
	// private stuff
	
	private Vector3 screenPos;
	private bool m_playerOnTribune = false;
	private bool m_aknowledgePlayerOnTribune = false;

	//--------
	// code

	/*private List<PersonageController> getPersonagesScripts() {
		List<PersonageController> myList;
		foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
			myList.Add((PersonageController)go.GetComponent(typeof(PersonageController)));
		}
		return myList;
	}*/
	
	// Use this for initialization
	void Start () {
		guiStyle.fontSize = 20;
		tribunePos = transform.position + new Vector3(0f, 0.9f, 0f);

		gameControllerScript = (GameController) GameObject.FindGameObjectWithTag("GameController").GetComponent(typeof(GameController));
	}

	// Update is called once per frame
	void Update () {
		screenPos = Camera.main.WorldToScreenPoint(transform.position);

		foreach (GameObject player in GameObject.FindGameObjectsWithTag("player")) {
			PlayerController script = (PlayerController) player.GetComponent(typeof(PlayerController));
			if (script != null)
			{
				float dist = Vector3.Distance(script.getPosition(), transform.position);

				// player is doing a meeting
				if (dist < 3f && gameControllerScript.getGameMode() >= GameController.GameMode.GAME_MODE_TRIBUNE)
				{
					m_playerOnTribune = true;

					script.setInTribune(true);
					// movement player to the tribune
					player.transform.position += (tribunePos - player.transform.position) * Time.deltaTime * 10f * (3f-dist) / 3f;
				
					if (!m_aknowledgePlayerOnTribune) {
						m_aknowledgePlayerOnTribune = true;

						// move nazi personages in a procession in front of the tribune
						foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
							PersonageController script3 = (PersonageController) go.GetComponent(typeof(PersonageController));
							if (script3 != null && script3.isNazi() && !script3.isVictim()) {
								float angleCenterProcession = (float)Random.Range(-180,180)*Mathf.PI/180f;
								float distCenterProcession = (float)Random.Range(0,100)/20f;
								script3.setTargetTribune(transform.position + new Vector3(
									-3.5f + Mathf.Cos(angleCenterProcession)*distCenterProcession, 
									0f, 
									Mathf.Sin(angleCenterProcession)*distCenterProcession));
							}
						}
					}

				}
				else
				{
					m_playerOnTribune = false;
					script.setInTribune(false);
					if (m_aknowledgePlayerOnTribune)
					{
						m_aknowledgePlayerOnTribune = false;

						// reset nazi personages to wander mode
						foreach (GameObject go in GameObject.FindGameObjectsWithTag("personage")) {
							PersonageController script2 = (PersonageController) go.GetComponent(typeof(PersonageController));
							if (script2 != null && script2.isNazi() && script2.isTargetVictimSet()) {
								script2.setWandering();
							}
						}

					}


				}
				// reset player height to the ground
				if (dist > 1f) {
					if (player.transform.position.y > 0.4f) player.transform.position -= new Vector3(0f, player.transform.position.y * Time.deltaTime * 1.5f, 0f);
				}
			}
		}
	}

	public bool isPlayerOnTribune() { return m_playerOnTribune;	}
	
	void OnGUI() {
		//GUI.Label (new Rect (10, 10, Screen.width, Screen.height), "" + gameControllerScript.getNbNazis(), guiStyle);
		Rect rect = new Rect (screenPos.x - 70, (Screen.height - screenPos.y) - 150, 100, 100);

		if (m_playerOnTribune) {

			// choose the texture of bubble
			Texture texture = textureBubbleNazi;
			if        (gameControllerScript.getGameMode()==GameController.GameMode.GAME_MODE_BLUE_YELLOW) {
				texture = textureBubbleBlueEqualYellow;
			} else if (gameControllerScript.getGameMode()==GameController.GameMode.GAME_MODE_PRISON) {
				texture = textureBubblePrison;
			} else if (gameControllerScript.getGameMode()==GameController.GameMode.GAME_MODE_ATTACKS) {
				texture = textureBubbleAttackYellow;
			}
			
			GUI.DrawTexture (rect, texture);

		} else if (gameControllerScript.getGameMode() == GameController.GameMode.GAME_MODE_NOTHING) {

			GUI.DrawTexture ( rect, textureBubbleNoLogo);
			GUI.Label (
				new Rect (screenPos.x - 70 + 20, (Screen.height - screenPos.y) - 150 + 20, Screen.width, Screen.height), 
				"" + gameControllerScript.getNbNazis() + " / " + gameControllerScript.getNbForTribune(), 
				guiStyle);
		}
	}

}

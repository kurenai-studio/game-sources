using UnityEngine;
using System.Collections;

public class PrisonController : MonoBehaviour {
	
	//--------
	// private stuff
	
	private GameController gameControllerScript = null;
	
	//--------
	// code
	
	// Use this for initialization
	void Start () {
		gameControllerScript = (GameController) GameObject.FindGameObjectWithTag("GameController").GetComponent(typeof(GameController));
	}
	
	//Vector3 getPos() { return transform.position + new Vector3 (0f, 0f, 0f); }

	// Update is called once per frame
	void Update () {

		if (gameControllerScript.getGameMode() >= GameController.GameMode.GAME_MODE_PRISON) {

			if (transform.position.y < 0.9f) {
				transform.position += new Vector3(0f, Time.deltaTime * 1f, 0f);
				if (transform.position.y >= 0.9f){
					transform.position.Set (transform.position.x, 0f, transform.position.z);
				}
			}
		}
	}
}

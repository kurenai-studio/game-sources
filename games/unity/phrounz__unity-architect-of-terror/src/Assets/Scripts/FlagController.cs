using UnityEngine;
using System.Collections;

public class FlagController : MonoBehaviour {

	public Texture textureFlag;

	//--------
	// constants
	
	private const float INTENSITY_MVT = 0.05f;
	private const float SPEED_MVT = 1f;

	//--------
	// private stuff
	
	private GameController gameControllerScript = null;
	private bool changedFlag = false;

	//--------
	// code
	
	// Use this for initialization
	void Start () {
		gameControllerScript = (GameController) GameObject.FindGameObjectsWithTag("GameController")[0].GetComponent(typeof(GameController));
	}

	// Update is called once per frame
	void Update () {

		//---------------------
		// enable flag if required
		
		if (gameControllerScript.getGameMode() >= GameController.GameMode.GAME_MODE_FLAG && !changedFlag) {
			GetComponent<Renderer>().material.mainTexture = textureFlag;
			changedFlag = true;
		}
		if (changedFlag) {
			if (transform.position.y > 5.4f) {
				transform.position -= new Vector3(0f, Time.deltaTime * 4f, 0f);
				if (transform.position.y < 5.4f) {
					transform.position.Set (transform.position.x, transform.position.y + Time.deltaTime * 0.5f, transform.position.z);
				}
			}
		}

		//---------------------
		// wind

		MeshFilter mf = GetComponent<MeshFilter>();
		Mesh mesh = mf.mesh;
		
		Vector3[] vertices = mesh.vertices;
		Bounds bounds = mesh.bounds;

		int i = 0;
		while (i < vertices.Length) {
			float factorX = (bounds.max.x - vertices[i].x) / (bounds.max.x - bounds.min.x);
			float factorZ = (bounds.max.z - vertices[i].z) / (bounds.max.z - bounds.min.z);
			Vector3 vertMove = new Vector3(0f, INTENSITY_MVT * Mathf.Sin ((float)Time.time*SPEED_MVT) * (1f-Mathf.Cos(factorZ)) * (1f-Mathf.Cos(factorX)),0f);
			vertices[i] += vertMove;
			i++;
		}
		
		mesh.vertices = vertices;
		mesh.RecalculateBounds();
	}
}

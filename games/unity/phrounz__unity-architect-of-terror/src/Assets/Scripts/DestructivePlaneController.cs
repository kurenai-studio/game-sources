using UnityEngine;
using System.Collections;

public class DestructivePlaneController : MonoBehaviour {
	
	//--------
	// constants
	
	private const float INTENSITY_MVT = 0.1f;
	//private bool endCrash = false;
	
	//--------
	// private stuff
	
	private GameController gameControllerScript = null;
	
	//--------
	// code
	
	// Use this for initialization
	void Start () {
		gameControllerScript = (GameController) GameObject.FindGameObjectWithTag("GameController").GetComponent(typeof(GameController));
	}
	
	// Update is called once per frame
	void Update () {
		/*if (gameControllerScript.isModeMeetingOk ()) { // && !endCrash
			
			MeshFilter mf = GetComponent<MeshFilter>();
			Mesh mesh = mf.mesh;
			
			Vector3[] vertices = mesh.vertices;
			Bounds bounds = mesh.bounds;
			
			int i = 0;
			while (i < vertices.Length) {
				float factorX = ((bounds.max.x - vertices[i].x)*Mathf.PI) / (bounds.max.x - bounds.min.x)-Mathf.PI/2f;
				float factorZ = ((bounds.max.z - vertices[i].z)*Mathf.PI) / (bounds.max.z - bounds.min.z)-Mathf.PI/2f;
				vertices[i] -= new Vector3(0f, INTENSITY_MVT * Mathf.Min((Mathf.Cos(factorZ)), (Mathf.Cos(factorX))), 0f);
				i++;
				if (vertices[i].y < -30000f) {endCrash = true;Destroy(GetComponent<MeshCollider>());}
			}
			
			mesh.vertices = vertices;
			mesh.RecalculateBounds();
		}
		
		*/
	}
}

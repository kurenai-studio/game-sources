using UnityEngine;
using System.Collections;

public class CameraPivotController : MonoBehaviour {

	public Transform player;
	private float yRotation;

	// Use this for initialization
	void Start () {
		this.transform.position = player.position;
		this.yRotation = this.transform.rotation.y;
	}
	
	// Update is called once per frame
	void Update () {
		this.transform.position = player.position;
		 
		// float xAxis = Input.GetAxis ("Horizontal");
		// Debug.Log ("Current axis: " + xAxis);
		 
		// yRotation += 1;
		// this.transform.rotation = Quaternion.Euler(0, yRotation, 0);
	}
}

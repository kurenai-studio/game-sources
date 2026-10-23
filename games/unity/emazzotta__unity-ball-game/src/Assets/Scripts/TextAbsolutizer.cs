using UnityEngine;
using System.Collections;

public class TextAbsolutizer : MonoBehaviour {

	public GameObject camera;
	public GameObject player;
	private Vector3 offset;

	// Use this for initialization
	void Start () {
		offset = this.transform.position;
	}

	// Update is called once per frame
	void Update () {
		this.transform.position = player.transform.position + offset;
		// this.transform.LookAt (camera.transform);
	}
}

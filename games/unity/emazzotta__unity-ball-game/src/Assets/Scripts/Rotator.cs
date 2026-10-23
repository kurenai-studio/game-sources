using UnityEngine;
using System.Collections;

public class Rotator : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
		transform.Rotate (new Vector3 (50, 50, 50) * Time.deltaTime);
	}

	void OnTriggerEnter(Collider collidee) {
		Destroy(this.gameObject);
	}
}

using UnityEngine;
using System.Collections;

public class Waver : MonoBehaviour {

	public float speed = 30f;
	public float distance = 20f;
	public float variation = 10f;

	private float location = 0;
	private bool goingLeft;

	// Use this for initialization
	void Start () {
		goingLeft = Random.Range(0,2) == 0;
		distance += Random.Range(-variation, variation);
		speed += Random.Range(-variation, variation);
	}
	
	// Update is called once per frame
	void Update () {
		float move = (goingLeft? speed: -speed)*Time.deltaTime;
		location += move;
		transform.Translate(move, 0, 0);
		if(goingLeft) {
			if(location > distance)
				goingLeft = false;
		} else {
			if(location < -distance)
				goingLeft = true;
		}

	}
}

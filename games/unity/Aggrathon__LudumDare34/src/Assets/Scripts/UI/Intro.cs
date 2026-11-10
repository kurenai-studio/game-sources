using UnityEngine;
using System.Collections;

public class Intro : MonoBehaviour {

	public GameObject ship;
	
	void Start () {
		if (ship == null)
			ship = GameObject.FindGameObjectWithTag("Player");
		ship.SetActive(false);
	}
	
	void Update () {
		if(Input.GetButton("Left") && Input.GetButton("Right"))
		{
			Begin();
		}
	}

	public void Begin()
	{
		ship.SetActive(true);
		gameObject.SetActive(false);
	}
}

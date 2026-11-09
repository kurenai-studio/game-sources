using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraFollow : MonoBehaviour {

	public Transform player;
	private static string songName;
	private static ulong songTime;
	private static AudioSource audioSource;

	void Awake () {
		audioSource = GetComponent<AudioSource>();
		if (audioSource.clip.name.Equals (songName)) {
			audioSource.Play (songTime);
		} else {
			audioSource.Play ();
			songName = audioSource.clip.name;
		}
	}

	// Update is called once per frame
	void Update () {
		songTime = (ulong) audioSource.time;

		if(player==null) return;
		Vector3 pos = player.position;
		transform.position = new Vector3(
			pos.x,
			pos.y,
			transform.position.z
		);
	}

	public static void setMusic (AudioClip clip){
		songTime = 0;
		songName = clip.name;
		audioSource.clip = clip;
		audioSource.Play ();
	}
}

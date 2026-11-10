using UnityEngine;
using System.Collections;

public class SoundManager : MonoBehaviour {

	public static SoundManager instance;

	AudioSource aud;
	
	void Awake () {
		instance = this;
		aud = GetComponent<AudioSource>();
	}

	public void PlaySound(AudioClip clip)
	{
		aud.PlayOneShot(clip);
	}
}

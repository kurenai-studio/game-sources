using UnityEngine;
using System.Collections;

public class FireFX : MonoBehaviour {

	AudioSource aud;
	ParticleSystem ps;
	
	void Awake () {
		aud = GetComponent<AudioSource>();
		ps = GetComponentInChildren<ParticleSystem>();
	}

	public void Fire(Vector3 pos, Quaternion rot)
	{
		transform.position = pos;
		transform.rotation = rot;
		ps.Stop(true);
		ps.Play(true);
		aud.Play();
	}
}

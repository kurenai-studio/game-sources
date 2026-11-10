using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class RobotAlerter : MonoBehaviour {

	public LayerMask enemyLayer;
	public float alertRadius = 20f;
	public AudioClip pickupSound;
	public AudioClip collisionSound;

	static float lastTime;
	float enableTime;
	Collider[] buffer;

	void OnEnable()
	{
		enableTime = Time.time;
	}

	void OnCollisionEnter(Collision col)
	{

		if (collisionSound != null && Time.time - lastTime > 0.2f)
		{
			GetComponent<AudioSource>().PlayOneShot(collisionSound);
		}
		if (Time.time - lastTime < 1f)
			return;

		if (buffer == null)
			buffer = new Collider[20];
		RobotAI.Alert(transform.position);
		int count = Physics.OverlapSphereNonAlloc(transform.position, alertRadius, buffer, enemyLayer);
		for (int i = 0; i < count; i++)
		{
			buffer[i].GetComponent<RobotAI>().ForceCheckArea(transform.position);
		}
		lastTime = Time.time;
		Debug.Log(count);
	}
	
	void OnTriggerEnter(Collider col)
	{
		if (enabled && Time.time - enableTime > 0.5f && col.transform.CompareTag("Player"))
		{
			GameState.instance.player.AddThrowable();
			GetComponent<AudioSource>().PlayOneShot(pickupSound);
			enabled = false;
			Destroy(gameObject, pickupSound.length);
		}
	}
}

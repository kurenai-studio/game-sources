using UnityEngine;
using System.Collections;

public class Looper : MonoBehaviour {

	private Vector3 random;

	public float speed = 10f;
	public float turnSpeed = 1f;
	public float randomness = 2f;
	public float randomInterval = 2f;
	
	Vector3 direction;
	
	void Start()
	{
		speed += Random.Range(-randomness, +randomness);
	}

	void OnEnable()
	{
		float rotation = Random.Range(0f, 360f);
		direction = new Vector3(Mathf.Sin(rotation), Mathf.Cos(rotation), 0f);
		StartCoroutine(RandomChange());
	}

	void Update ()
	{
		Vector3 targetDirection = -transform.localPosition + random;
		if (Vector3.Angle(direction, targetDirection) > 179.9f)
		{
			float rotation = Random.Range(0f, 360f);
			targetDirection = new Vector3(Mathf.Sin(rotation), Mathf.Cos(rotation), 1f);
		}
		direction = Vector3.RotateTowards(direction, targetDirection, turnSpeed * Time.deltaTime, 1f);
		direction.z = 0;
		direction.Normalize();

		transform.position += direction * speed * Time.deltaTime;
	}

	IEnumerator RandomChange()
	{
		WaitForSeconds wait = new WaitForSeconds(randomInterval);
		while (true)
		{
			random = Random.onUnitSphere * randomness;
			random.z = 0;
			yield return wait;
		}
	}
}

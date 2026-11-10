using UnityEngine;
using System.Collections;

public class Bullet : MonoBehaviour {
	public float speed = 50.0f;
	public Transform shooting;

	void FixedUpdate() {
		transform.position += transform.right * speed * Time.fixedDeltaTime;
	}

	public IEnumerator Destroy() {
		yield return new WaitForSeconds(0);

		if (shooting.GetComponent<Pistol>()) shooting.GetComponent<Pistol>().BulletRayCast(transform);
		else shooting.GetComponent<Machine>().BulletRayCast(transform);
		Destroy(gameObject);
	}
}

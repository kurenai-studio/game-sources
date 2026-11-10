using UnityEngine;
using System.Collections;

public class Missile : MonoBehaviour
{

	new private Rigidbody2D rigidbody;
	private float boost = 1f;

	public Transform target;

	public float speed = 2000f;
	public float turn = 3000f;
	public float angle = 30f;

	public float launchPeriod = 0.3f;

	void Awake()
	{
		rigidbody = GetComponent<Rigidbody2D>();
		angle *= Mathf.Deg2Rad;
	}

	void OnEnable()
	{
		boost = 10.0f;
		StartCoroutine(Later());
		gameObject.layer = 8;
	}

	IEnumerator Later()
	{
		yield return new WaitForSeconds(launchPeriod);
		gameObject.layer = 0;
		boost = 1.0f;
	}

	public void Setup(Rigidbody2D launcher, float acc, Transform target)
	{
		speed = acc;
		this.target = target;
		rigidbody.isKinematic = true;
		Vector2 offset = (Vector2)launcher.transform.up * 15f;
        rigidbody.position = launcher.position + offset;
		rigidbody.rotation = launcher.rotation;
		rigidbody.velocity = offset + launcher.velocity;
		rigidbody.angularVelocity = 0f;
		rigidbody.isKinematic = false;
	}

	void FixedUpdate()
	{
		if (target != null)
		{
			PhysicsFunctions.RigidBodyFollow(rigidbody, target.position, speed*boost, turn, angle);
		}
		else
		{
			gameObject.SetActive(false);
		}
	}

	public void OnCollisionEnter2D(Collision2D collision)
	{
		if (collision.gameObject.tag == "Sun")
		{
			gameObject.SetActive(false);
		}
		else if (collision.gameObject.tag == "Planet")
		{
			gameObject.SetActive(false);
			Planet p = collision.gameObject.GetComponent<Planet>();
			p.food = (int)0.9 * p.food;
			p.products = (int)0.9 * p.products;
			p.population = (int)0.9 * p.population;
		}
	}
}

using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Rigidbody2D))]
public class Pirate : MonoBehaviour
{
	private float rigDrag;
	private float rigAngDrag;
	new private Rigidbody2D rigidbody;
	private float missileTime;

	public Rigidbody2D target;
	public PlanetarySystem solarSystem;

	public float speed = 200f;
	public float turnSpeed = 3000f;
	public float boostAngle = 30f;
	public float missileCooldown = 5.0f;
	public float missileSpeed = 2500f;
	public float missileMinDistance = 100f;
	public float missileMaxDistance = 500f;
	public GameObject missile;


	void Awake()
	{
		rigidbody = GetComponent<Rigidbody2D>();
		rigDrag = rigidbody.drag;
		rigAngDrag = rigidbody.angularDrag;
		boostAngle *= Mathf.Deg2Rad;
	}

	public void SetSolarSystem(PlanetarySystem ss)
	{
		solarSystem = ss;
		ss.registerPirate(rigidbody);
	}

	public void SetTarget(Rigidbody2D t)
	{
		if(t == null)
		{
			rigidbody.drag = 0f;
			rigidbody.angularDrag = 0f;
			rigidbody.angularVelocity = 0f;
			rigidbody.velocity = PhysicsFunctions.OrbitalSpeed(
				solarSystem.centerOfMass - rigidbody.position,
				solarSystem.totalMass, Random.Range(0,2)==1);
			rigidbody.rotation = Vector2.Angle(Vector2.up, rigidbody.velocity);
			target = null;
		}
		else
		{
			target = t;
			rigidbody.drag = rigDrag;
			rigidbody.angularDrag = rigAngDrag;
		}
    }

	void OnDisable()
	{
		if(solarSystem != null) 
			solarSystem.unregisterPirate(rigidbody);
		missileTime = 0f;
	}


	void FixedUpdate()
	{
		if(target != null && target.gameObject.activeSelf) {
			PhysicsFunctions.RigidBodyFollow(rigidbody, target.position, speed, turnSpeed, boostAngle);
			float magn = (rigidbody.position - target.position).magnitude;
			if (magn < missileMaxDistance && magn > missileMinDistance)
			{
				missileTime += Time.fixedDeltaTime;
				if(missileTime > missileCooldown)
				{
					missileTime = 0f;
					ObjectPool.GetObject(missile).GetComponent<Missile>().Setup(rigidbody, missileSpeed, target.transform);
				}
			}
			else
			{
				missileTime = 0f;
			}
		}
	}

	public void OnCollisionEnter2D(Collision2D collision)
	{
		if(collision.gameObject.tag == "Missile")
		{
			gameObject.SetActive(false);
			collision.gameObject.SetActive(false);
        }
		else if (collision.gameObject.tag == "Sun")
		{
			gameObject.SetActive(false);
		}
		else if (collision.gameObject.tag == "Planet")
		{
			gameObject.SetActive(false);
			Planet p = collision.gameObject.GetComponent<Planet>();
			p.food = 0;
			p.products = 0;
			p.population = 0;
        }
	}
}

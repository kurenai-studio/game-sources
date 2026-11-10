using UnityEngine;
using System.Collections;
using System;

public class HeliAI : Unit
{
	public float flightHeight = 25f;
	public float maxSpeed = 20f;
	public float turnSpeed = 100f;
	public float engineForce = 2f;
	public float velocityTilt = 70f;
	public Transform visual;
	public float range = 35f;
	public float damage = 200f;
	public float gunCooldown = 10f;
	public float fireRate = 0.1f;
	public float fireTime = 3f;
	public GameObject firePS;

	public override Vector3 destination { get; set; }

	int state = 10;
	float fireTimer = 0f;
	float fireCooldown = -1f;
	float reload = 99f;
	
	Rigidbody rigid;

	void Start()
	{
		rigid = GetComponent<Rigidbody>();
	}

	void Update()
	{
		Vector3 speed = rigid.velocity;
		speed.y = 0;
		float tilt = speed.magnitude / maxSpeed;
		visual.localRotation = Quaternion.Euler(tilt* velocityTilt, 0f, 0f);

		switch(state)
		{
			case 0: //firing
				if (fireTimer < fireTime)
				{
					fireCooldown -= Time.deltaTime;
					if(fireCooldown < 0)
					{
						fireCooldown += fireRate;
						//FIRE
						RaycastHit hit;
						if (Physics.SphereCast(visual.position, 0.5f, visual.forward, out hit, range))
						{
							GameObjectPool.Get(firePS).GetComponent<FireFX>().Fire(hit.point, Quaternion.identity);
							Unit u = hit.collider.gameObject.GetComponent<Unit>();
							if (u != null && u.team != team)
							{
								this.target = u;
								u.Damage(damage);
							}
						}
					}

					fireTimer += Time.deltaTime;
				}
				else
				{
					this.target = null;
					fireTimer = 0f;
					state = 50;
					fireCooldown = -1f;
					reload = 0f;
				}
				break;
			case 1: //scanning;
				if(reload < fireCooldown)
				{
					reload += Time.deltaTime;
					state = 20;
				}
				else
				{
					//SCAN
					RaycastHit[] hit = Physics.SphereCastAll(visual.position, 0.5f, visual.forward, range);
					for (int i = 0; i < hit.Length; i++)
					{
						Unit u = hit[i].collider.gameObject.GetComponent<Unit>();
						if (u != null && u.team != team)
						{
							state = 0;
							target = u;
							Update();
							break;
						}
					}
					state = 8;
				}
				this.target = null;
				break;
			default:
				state--;
				reload += Time.deltaTime;
				break;
		}
	}

	void FixedUpdate()
	{
		Vector3 dir = new Vector3(destination.x - transform.position.x, 0f, destination.z - transform.position.z);
		if (dir.x != 0f || dir.z != 0f)
		{
			rigid.MoveRotation(Quaternion.RotateTowards(rigid.rotation, Quaternion.LookRotation(dir, Vector3.up), turnSpeed * Time.deltaTime));
			Vector3 move = Vector3.ClampMagnitude(transform.forward * dir.magnitude + Vector3.up * (flightHeight - transform.position.y), maxSpeed);
			rigid.AddForce(move* engineForce*Time.deltaTime,ForceMode.VelocityChange);
			rigid.velocity = Vector3.ClampMagnitude(rigid.velocity, maxSpeed);
		}
		else if (transform.position.y < flightHeight)
		{
			rigid.MovePosition(rigid.position+Vector3.ClampMagnitude(new Vector3(0f, (flightHeight - transform.position.y), 0f), maxSpeed) * Time.deltaTime);
		}
	}
}

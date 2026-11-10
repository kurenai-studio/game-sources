using UnityEngine;
using System.Collections.Generic;

public class TankAI : Unit
{
	[Header("TANK")]
	public Transform barrel;
	public float barrelTurnSpeed = 40f;
	public float range = 20f;
	public float fireRate = 1f;
	public float damage = 150f;
	public GameObject firePS;
	public Transform barrelPoint;

	float coolDown = 0f;
	int state = 0;

	UnityEngine.AI.NavMeshAgent navAgent;
	
	public override Vector3 destination
	{
		get { return navAgent.destination; }
		set { navAgent.destination = value; }
	}

	void Awake()
	{
		navAgent = GetComponent<UnityEngine.AI.NavMeshAgent>();
		enemyLost += (unit, target, first) => {
			if (this.target != null && this.state != 0 && this.target == target)
			{
				this.state = 0;
				this.target = null;
			}
		};
	}

	void Update()
	{
		RaycastHit hit;
		UnityEngine.AI.NavMeshHit nhit;
		switch (state)
		{
			case 1:
				if(!target.gameObject.activeSelf || navAgent.Raycast(target.transform.position, out nhit) || nhit.distance > range)
				{
					state = 0;
					target = null;
					break;
				}
				Vector3 targetV3 = target.transform.position;
				Quaternion targetRot = Quaternion.LookRotation(targetV3 - transform.position, transform.up);
				barrel.rotation = Quaternion.RotateTowards(barrel.rotation, targetRot, barrelTurnSpeed * Time.deltaTime);
				if (coolDown > fireRate && Physics.Raycast(barrel.position, barrel.forward, out hit, range))
				{
					Unit other = hit.collider.gameObject.GetComponent<Unit>();
					if (other != null && other.team != team)
					{
						coolDown = 0;
						GameObjectPool.Get(firePS).GetComponent<FireFX>().Fire(barrelPoint.position, barrelPoint.rotation);
						if (other.Damage(damage))	//FIRE
						{
							state = 0;
							this.target = null;
						}
					}
				}
				break;
			case 0:
			default:    //Find target
				var en = team.sightedEnemies.First;
				LinkedListNode<Unit> newTarget = null;
				if (en != null)
				{
					float angle = Mathf.Infinity;
					while (en.Next != null)
					{
						en = en.Next;
						if(!en.Value.gameObject.activeSelf)
						{
							team.sightedEnemies.Remove(en);
							continue;
						}
						if(en.Value.type.air)
						{
							continue;
						}
						Vector3 dir = en.Value.transform.position - transform.position;
						float angle2 = Quaternion.Angle(barrel.rotation, Quaternion.LookRotation(dir, transform.up));
						if (angle2 < angle && !navAgent.Raycast(en.Value.transform.position, out nhit) && nhit.distance < range)
						{
							angle = angle2;
							newTarget = en;
						}
					}
				}
				if (newTarget != null) {
					target = newTarget.Value;
					state = 1;
				}
				else
				{
					barrel.localRotation = Quaternion.RotateTowards(barrel.localRotation, Quaternion.identity, barrelTurnSpeed * Time.deltaTime);
				}
				break;
		}
		coolDown += Time.deltaTime;
	}
}

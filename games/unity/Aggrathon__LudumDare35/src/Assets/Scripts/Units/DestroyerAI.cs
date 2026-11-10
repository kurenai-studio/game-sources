using UnityEngine;
using System.Collections.Generic;

public class DestroyerAI : Unit
{
	[Header("IFV")]
	public float range = 20f;
	public float fireRate = 2f;
	public float damage = 250f;
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
	}

	void Update()
	{
		UnityEngine.AI.NavMeshHit hit;
		switch (state)
		{
			case 1:
				if (!target.gameObject.activeSelf || navAgent.Raycast(target.transform.position, out hit) || hit.distance > range)
				{
					state = 0;
					target = null;
					navAgent.Resume();
					break;
				}

				Vector3 targetV3 = target.transform.position;
				Quaternion targetRot = Quaternion.LookRotation(targetV3 - transform.position, transform.up);
				transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRot, navAgent.angularSpeed * Time.deltaTime);

				RaycastHit rhit;
				if (coolDown > fireRate && Physics.Raycast(transform.position+transform.up*1, transform.forward, out rhit, range))
				{
					Unit other = rhit.collider.gameObject.GetComponent<Unit>();
					if (other != null && other.team != team)
					{
						coolDown = 0;
						GameObjectPool.Get(firePS).GetComponent<FireFX>().Fire(barrelPoint.position, barrelPoint.rotation);
						if (other.Damage(damage))	//FIRE
						{
							state = 0;
							this.target = null;
							navAgent.Resume();
						}
					}
				}
				break;
			case 0:
			default:    //Find target
				navAgent.Resume();
				var en = team.sightedEnemies.First;
				LinkedListNode<Unit> newTarget = null;
				if (en != null)
				{
					float angle = Mathf.Infinity;
					while (en.Next != null)
					{
						en = en.Next;
						if (!en.Value.gameObject.activeSelf)
						{
							team.sightedEnemies.Remove(en);
							continue;
						}
						if (en.Value.type.air)
						{
							continue;
						}
						Vector3 dir = en.Value.transform.position - transform.position;
						float angle2 = Quaternion.Angle(transform.rotation, Quaternion.LookRotation(dir, transform.up));
						if (angle2 < angle && !navAgent.Raycast(en.Value.transform.position, out hit) && hit.distance < range)
						{
							angle = angle2;
							newTarget = en;
						}
					}
				}
				if (newTarget != null)
				{
					target = newTarget.Value;
					navAgent.Stop();
					state = 1;
				}
				break;
		}
		coolDown += Time.deltaTime;
	}
}

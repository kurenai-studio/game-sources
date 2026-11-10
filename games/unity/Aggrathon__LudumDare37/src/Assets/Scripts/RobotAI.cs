using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

[RequireComponent(typeof(NavMeshAgent))]
[DisallowMultipleComponent]
[RequireComponent(typeof(AudioSource))]
public class RobotAI : MonoBehaviour {

	enum State
	{
		Patrolling,
		Hunting,
		Firing
	}

	public GameObject bucketPrefab;
	public Transform bucketPlace;

	[Header("Patrol")]
	public Transform patrol;
	public float patrolDistance = 4f;
	public bool patrolForward = true;
	public int patrolFirstPoint = 0;
	int patrolPosition;

	[Header("Tracking")]
	public float trackingAngle = 80f;
	public float trackingDistance = 30f;
	public float headRotation = 180f;
	public Transform trackingHead;

	static Vector3 lastTargetPosition;
	static int lastPositionCounter;
	Transform trackingTarget;
	int lastPositionLookedAt;

	[Header("Firing")]
	public float fireCooldown = 5f;
	public float fireRange = 10f;
	public float fireDuration = 0.5f;
	public LineRenderer fireLazer;
	float lastFire;

	[Header("Sounds")]
	public AudioClip audioLostTracking;
	public AudioClip audioTracking;
	public AudioClip audioChargeUp;
	public AudioClip audioExplosion;
	new AudioSource audio;

	NavMeshAgent navAgent;
	State state;

	void Start()
	{
		navAgent = GetComponent<NavMeshAgent>();
		audio = GetComponent<AudioSource>();
		trackingTarget = GameState.instance.player.transform;
		patrolPosition = patrolFirstPoint % patrol.childCount;
		navAgent.SetDestination(patrol.GetChild(patrolPosition).position);
		state = State.Patrolling;
	}

	void Update()
	{
		Vector3 dir;
		switch (state)
		{
			case State.Patrolling:
				if (CheckVisible())
				{
					HuntState();
					return;
				}
				if (Vector3.Distance(transform.position, patrol.GetChild(patrolPosition).position) < patrolDistance)
				{
					if (patrolForward)
						patrolPosition = (patrolPosition + 1) % patrol.childCount;
					else
						patrolPosition = (patrolPosition + patrol.childCount - 1) % patrol.childCount;
					navAgent.SetDestination(patrol.GetChild(patrolPosition).position);
				}
				if(lastPositionLookedAt == lastPositionCounter)
					trackingHead.localRotation = Quaternion.RotateTowards(trackingHead.localRotation, new Quaternion(0,0,0,1),headRotation*Time.deltaTime);
				else
				{
					dir = lastTargetPosition - transform.position;
					dir.y = 0;
					if (Vector3.Angle(trackingHead.forward, dir) < trackingAngle * 0.25f)
						lastPositionLookedAt = lastPositionCounter;
					trackingHead.rotation = Quaternion.RotateTowards(trackingHead.rotation, Quaternion.LookRotation(dir, Vector3.up), headRotation * Time.deltaTime);
				}

				break;

			case State.Hunting:
				if((trackingTarget.position-lastTargetPosition).sqrMagnitude > 2f && CheckVisible())
				{
					navAgent.SetDestination(lastTargetPosition);
				}
				dir = lastTargetPosition - transform.position;
				dir.y = 0;
				float magn = dir.sqrMagnitude;
				if (Time.time-lastFire > fireCooldown && magn < fireRange*fireRange && CheckVisible())
				{
					FireState();
				}
				else if(magn < 4f)
				{
					if((trackingTarget.position-transform.position).sqrMagnitude < 4f)
					{
						lastTargetPosition = trackingTarget.position;
						navAgent.SetDestination(lastTargetPosition);
						dir = lastTargetPosition - transform.position;
					}
					else
					{
						PatrolState();
						return;
					}
				}
				else if(navAgent.remainingDistance < 1f || navAgent.remainingDistance > 1000f)
				{
					PatrolState();
					return;
				}
				if(magn < float.Epsilon)
				{
					PatrolState();
					return;
				}
				trackingHead.rotation = Quaternion.RotateTowards(trackingHead.rotation, Quaternion.LookRotation(dir, Vector3.up), headRotation*Time.deltaTime);
				break;

			case State.Firing:
				if(Time.time-lastFire<audioChargeUp.length)
				{
					CheckVisible();
					dir = lastTargetPosition - transform.position;
					dir.y = 0;
					trackingHead.rotation = Quaternion.RotateTowards(trackingHead.rotation, Quaternion.LookRotation(dir, Vector3.up), headRotation * Time.deltaTime);
				}
				else
				{
					audio.clip = audioExplosion;
					audio.Play();
					lastFire = Time.time+audioExplosion.length+0.1f;
					StartCoroutine(AfterFire());
					fireLazer.SetPosition(0, fireLazer.transform.position);
					RaycastHit hit;
					if(Physics.Raycast(fireLazer.transform.position + fireLazer.transform.forward, fireLazer.transform.forward, out hit, 200f))
					{
						fireLazer.SetPosition(1, hit.point);
						if(hit.transform.CompareTag("Player"))
						{
							GameState.instance.onPlayerDeath.Invoke();
						}
					}
					else
					{
						fireLazer.SetPosition(1, fireLazer.transform.position+fireLazer.transform.forward*200f);
					}
					StartCoroutine(FlashLazer());
				}
				break;
		}

	}

	bool CheckVisible()
	{
		Vector3 direction = trackingTarget.position - trackingHead.position;
		if (direction.sqrMagnitude < trackingDistance * trackingDistance)
		{
			if (Vector3.Angle(direction, trackingHead.forward) < trackingAngle)
			{
				RaycastHit hit;
				if (Physics.Raycast(trackingHead.position+trackingHead.forward*0.5f, direction, out hit, trackingDistance))
				{
					if (hit.collider.CompareTag("Player"))
					{
						lastTargetPosition = hit.transform.position;
						lastPositionCounter++;
						return true;
					}
				}
			}
		}
		return false;
	}

	void FireState()
	{
		if (state != State.Firing)
		{
			navAgent.Stop();
			audio.Stop();
			audio.loop = false;
			audio.clip = audioChargeUp;
			audio.Play();
			state = State.Firing;
			lastFire = Time.time;
		}
	}

	void HuntState()
	{
		if (state != State.Hunting)
		{
			audio.Stop();
			audio.loop = true;
			audio.clip = audioTracking;
			audio.Play();
			state = State.Hunting;
		}
		navAgent.SetDestination(lastTargetPosition);
	}

	void PatrolState()
	{
		if (state != State.Patrolling)
		{
			audio.Stop();
			audio.loop = false;
			audio.clip = audioLostTracking;
			audio.Play();
			state = State.Patrolling;
			navAgent.SetDestination(patrol.GetChild(patrolPosition).position);
		}
	}

	IEnumerator AfterFire()
	{
		yield return new WaitForSeconds(audioExplosion.length);
		if (CheckVisible())
			HuntState();
		else
			PatrolState();
		navAgent.Resume();
	}

	IEnumerator FlashLazer()
	{
		fireLazer.gameObject.SetActive(true);
		yield return new WaitForSeconds(fireDuration);
		fireLazer.gameObject.SetActive(false);
	}

	void OnDrawGizmosSelected()
	{
		Gizmos.color = Color.blue;
		if(patrol!=null && patrolFirstPoint >= 0 && patrolFirstPoint < patrol.childCount)
		{
			Gizmos.DrawLine(transform.position, patrol.GetChild(patrolFirstPoint).position);
		}
	}

	public static void Alert(Vector3 position)
	{
		lastTargetPosition = position;
		lastPositionCounter++;
	}

	public void ForceCheckArea(Vector3 position)
	{
		if(enabled)
		{
			Alert(position);
			HuntState();
		}
	}

	public void Disable()
	{
		enabled = false;
		audio.Stop();
		audio.loop = false;
		audio.clip = audioLostTracking;
		audio.Play();
		navAgent.Stop();
		Instantiate(bucketPrefab, bucketPlace,false);
	}
}

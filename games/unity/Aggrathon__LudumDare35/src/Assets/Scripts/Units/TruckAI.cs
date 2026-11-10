using UnityEngine;

public class TruckAI : Unit
{
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
}

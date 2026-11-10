using UnityEngine;
using System.Collections;

public class TargetTrigger : MonoBehaviour
{

	public void OnTriggerEnter(Collider other)
	{
		if(other.isTrigger || other.gameObject.isStatic)
			return;
		Unit u = other.gameObject.GetComponent<Unit>();
		if(u != null)
		{
			u.team.tickerUnits.Add(u);
		}
	}

	public void OnTriggerExit(Collider other)
	{
		if (other.isTrigger)
			return;
		Unit u = other.gameObject.GetComponent<Unit>();
		if (u != null)
		{
			u.team.tickerUnits.Remove(u);
		}
	}
}

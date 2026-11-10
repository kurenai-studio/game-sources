using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Serialization;

public class TriggerEvent : MonoBehaviour {
	public bool playerOnly;
	[FormerlySerializedAs("onTrigger")]
	public UnityEvent onEnter;
	public UnityEvent onExit;

	void OnTriggerEnter(Collider col)
	{
		if (!playerOnly || col.transform.CompareTag("Player"))
		{
			onEnter.Invoke();
		}
	}

	void OnTriggerExit(Collider col)
	{
		if (!playerOnly || col.transform.CompareTag("Player"))
		{
			onExit.Invoke();
		}
	}
}

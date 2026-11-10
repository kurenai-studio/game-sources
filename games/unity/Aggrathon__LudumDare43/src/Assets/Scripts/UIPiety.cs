using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class UIPiety : MonoBehaviour
{
	public State player;
	public Image meter;

	void Start()
	{
		GameManager.RegisterOnTick(Tick);
		meter.fillAmount = player.piety;
	}
	
	public void Tick()
	{
		meter.fillAmount = player.piety;
	}

	public void UpdateNextTick()
	{
		StartCoroutine(NextTick());
	}

	IEnumerator NextTick()
	{
		yield return null;
		Tick();
	}
}

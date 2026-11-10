using UnityEngine;
using System.Collections;
using TMPro;

public class UIModifiers : MonoBehaviour
{
	public State player;

	int numModifiers = 0;
	AStateModifier lastMod = null;

	public void Tick()
	{
		if (numModifiers == 0 && player.modifiers.Count == 0)
			return;
		if (numModifiers == player.modifiers.Count && player.modifiers[player.modifiers.Count - 1] == lastMod)
			return;
		numModifiers = player.modifiers.Count;
		if (numModifiers != 0)
			lastMod = player.modifiers[player.modifiers.Count - 1];
		for (int i = transform.childCount; i < numModifiers; i++)
			Instantiate(transform.GetChild(0), transform);
		for (int i = 0; i < player.modifiers.Count; i++)
		{
			Transform panel = transform.GetChild(i);
			panel.GetChild(0).GetComponent<TextMeshProUGUI>().text = player.modifiers[i].name;
			panel.GetChild(1).GetComponent<TextMeshProUGUI>().text = player.modifiers[i].description;
			panel.gameObject.SetActive(true);
		}
		for (int i = numModifiers; i < transform.childCount; i++)
			transform.GetChild(i).gameObject.SetActive(false);
	}
}

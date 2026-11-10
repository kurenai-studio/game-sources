using UnityEngine;
using System.Collections.Generic;
using System;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class UIStateSelectors : MonoBehaviour
{
	public Button attackButton;
	public Button selectButton;
	public State state;
	public bool isPlayer;

	static List<UIStateSelectors> list;
	static Action<State> onSelect;
	static State player;

	private void Awake()
	{
		if(isPlayer)
		{
			list = new List<UIStateSelectors>();
			player = state;
		}
	}
	
	void Start()
	{
		if (!isPlayer) {
			list.Add(this);
			selectButton.gameObject.SetActive(false);
		}
		else
			gameObject.SetActive(false);
	}

	public static void SelectState(Action<State> callback)
	{
		onSelect = callback;
		for (int i = 0; i < list.Count; i++)
		{
			list[i].selectButton.gameObject.SetActive(true);
			list[i].attackButton.gameObject.SetActive(false);
		}
	}

	public void StopSelection()
	{
		for (int i = 0; i < list.Count; i++)
		{
			list[i].selectButton.gameObject.SetActive(false);
			list[i].attackButton.gameObject.SetActive(true);
		}
	}
	
	public void Select()
	{
		for (int i = 0; i < list.Count; i++)
		{
			list[i].selectButton.gameObject.SetActive(false);
			list[i].attackButton.gameObject.SetActive(true);
		}
		onSelect(state);
	}

	public void Attack()
	{
		EventSystem.current.SetSelectedGameObject(null);
		player.Attack(state);
	}
}
